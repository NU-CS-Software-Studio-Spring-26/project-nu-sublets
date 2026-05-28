require "test_helper"

class PagesFlowTest < ActionDispatch::IntegrationTest
  include ActiveSupport::Testing::TimeHelpers

  setup do
    @previous_openai_api_key = ENV["OPENAI_API_KEY"]
    ENV["OPENAI_API_KEY"] = nil
    travel_to Date.new(2026, 5, 1)
  end

  teardown do
    travel_back
    ENV["OPENAI_API_KEY"] = @previous_openai_api_key
  end

  test "home page is reachable" do
    get root_path

    assert_response :success
  end

  test "listing page is reachable" do
    get listing_path

    assert_response :success
  end

  test "search results page is reachable" do
    get search_results_path

    assert_response :success
  end

  test "saved page is reachable" do
    get saved_path

    assert_response :success
  end

  test "post sublet page is reachable" do
    get post_sublet_path

    assert_response :success
  end

  test "about us page is reachable from the footer" do
    get root_path

    assert_select "footer a[href='#{about_us_path}']", text: "About Us"
    assert_select "footer a[href='https://github.com/NU-CS-Software-Studio-Spring-26/project-nu-sublets'][target='_blank'][rel='noopener']", text: "GitHub Repository"

    get about_us_path

    assert_response :success
    assert_select "h1", text: "About Us"
    assert_select "h2", text: "About NU Sublets"
    assert_includes response.body, "NU Sublets is a student-built platform designed to make the Northwestern sublet process easier, safer, and more organized."
    assert_includes response.body, "not officially affiliated with, endorsed by, or managed by Northwestern University"
  end

  test "disclaimer page is reachable from the footer" do
    get root_path

    assert_select "footer a[href='#{disclaimer_path}']", text: "Disclaimer"

    get disclaimer_path

    assert_response :success
    assert_select "h1", text: "Disclaimer / Terms of Use"
    assert_select "h2", text: "Disclaimer"
    assert_includes response.body, "NU Sublets does not own, manage, inspect, or verify the condition, legality, price, availability, or safety of any listed property."
    assert_includes response.body, "By using NU Sublets, you agree to use the platform responsibly"
  end

  test "login page is reachable" do
    get login_path

    assert_response :success
  end

  test "about page is reachable from the footer" do
    get about_path

    assert_response :success
    assert_select "h1", text: "About NU Sublets"
    assert_select "a[href='#{about_path}']", text: "About Us"
  end

  test "login page redirects after sign in" do
    sign_in_with_firebase_email("student@u.northwestern.edu")

    get login_path

    assert_redirected_to profile_path
  end

  test "post sublet form requires login" do
    post submit_sublet_path, params: {
      "street-address" => "820 Noyes St",
      "city" => "Evanston",
      "state" => "IL",
      "zip-code" => "60201",
      "price" => "850"
    }

    assert_redirected_to login_path
  end

  test "logged in post sublet form submits to an app endpoint" do
    sign_in_with_firebase_email("student@u.northwestern.edu")

    assert_difference("SubletListing.count", 1) do
      post submit_sublet_path, params: valid_sublet_post_params
    end

    listing = SubletListing.order(:created_at).last

    assert_equal Date.new(2026, 6, 12), listing.available_from
    assert_equal Date.new(2026, 9, 11), listing.available_until
    assert_equal [ "Laundry", "Gym" ], listing.amenities
    assert_equal [ "Graduate student", "Quiet" ], listing.preferences
    assert_redirected_to search_results_path("move-in": "06/12/2026", "move-out": "09/11/2026")
  end

  test "invalid sublet photo upload shows a friendly error and preserves input" do
    sign_in_with_firebase_email("student@u.northwestern.edu")
    upload = uploaded_test_file("lease.pdf", "application/pdf", "%PDF-1.4 fake pdf")

    assert_no_difference("SubletListing.count") do
      post submit_sublet_path, params: valid_sublet_post_params.merge(photos: [ upload ])
    end

    assert_response :unprocessable_entity
    assert_includes response.body, "Photos must be PNG, JPG, or WebP files."
    assert_select "input[name='street-address'][value='820 Noyes St']"
  end

  test "home page links to the other product views" do
    get root_path

    assert_select "a[href='#{search_results_path}']", text: /Search/
    assert_select "a[href='#{saved_path}']", text: /Saved/
    assert_select "a[href='#{post_sublet_path}']", text: /Post Sublet|Create a Posting/
    assert_select "a[href='#{profile_path}']", text: "Profile", count: 0
    assert_select "a[href='#{login_path}']", text: /Log in/
    assert_select "a.listing-card[href]"
  end

  test "home browse cards use database listing owners and stored profile photos" do
    user = User.create!(
      name: "Ryan Anderson",
      email: "ryan.anderson@u.northwestern.edu",
      profile_photo_url: "https://example.com/ryan-anderson.jpg",
      active: true
    )
    listing = user.sublet_listings.create!(
      valid_listing_attributes.merge(
        title: "Ryan's Campus Sublet",
        available_from: Date.new(2026, 5, 24),
        available_until: Date.new(2026, 10, 3)
      )
    )

    get root_path

    assert_response :success
    assert_select "a[href='#{sublet_listing_path(listing)}'] img.listing-avatar[alt='Ryan Anderson profile photo'][src='https://example.com/ryan-anderson.jpg']"
  end

  test "home page includes recommendation filter controls" do
    get root_path

    assert_select "form[action='#{root_path(anchor: "recommendations")}'][method='get'][aria-label='Filter recommended sublets']"
    assert_select "input[name='recommendation_move_in']"
    assert_select "input[name='recommendation_move_out']"
    assert_select "select[name='recommendation_bedrooms']"
    assert_select "select[name='recommendation_bathrooms']"
    assert_select "input[name='recommendation_amenities[]'][value='Laundry']"
  end

  test "home recommendation filters narrow recommended carousel without changing newest carousel" do
    user = User.create!(
      name: "Recommendation Owner",
      email: "recommendation.owner@u.northwestern.edu",
      active: true
    )
    matching_listing = user.sublet_listings.create!(
      valid_listing_attributes.merge(
        title: "Filtered Recommendation Match",
        price: 900,
        bedrooms: 2,
        bathrooms: 1,
        amenities: [ "Laundry", "Gym" ],
        available_from: Date.new(2026, 6, 1),
        available_until: Date.new(2026, 10, 1)
      )
    )
    missing_bedroom = user.sublet_listings.create!(
      valid_listing_attributes.merge(
        title: "Filtered Recommendation Wrong Bedroom",
        price: 800,
        bedrooms: 1,
        bathrooms: 1,
        amenities: [ "Laundry", "Gym" ],
        available_from: Date.new(2026, 6, 1),
        available_until: Date.new(2026, 10, 1)
      )
    )
    missing_amenity = user.sublet_listings.create!(
      valid_listing_attributes.merge(
        title: "Filtered Recommendation Missing Gym",
        price: 700,
        bedrooms: 2,
        bathrooms: 1,
        amenities: [ "Laundry" ],
        available_from: Date.new(2026, 6, 1),
        available_until: Date.new(2026, 10, 1)
      )
    )
    outside_window = user.sublet_listings.create!(
      valid_listing_attributes.merge(
        title: "Filtered Recommendation Wrong Window",
        price: 600,
        bedrooms: 2,
        bathrooms: 1,
        amenities: [ "Laundry", "Gym" ],
        available_from: Date.new(2026, 6, 1),
        available_until: Date.new(2026, 8, 1)
      )
    )

    get root_path(
      recommendation_move_in: "06/12/2026",
      recommendation_move_out: "09/11/2026",
      recommendation_bedrooms: "2",
      recommendation_bathrooms: "1",
      recommendation_amenities: [ "Laundry", "Gym" ]
    )

    assert_select "#recommendations-track a[href='#{sublet_listing_path(matching_listing)}']"
    assert_select "#recommendations-track a[href='#{sublet_listing_path(missing_bedroom)}']", count: 0
    assert_select "#recommendations-track a[href='#{sublet_listing_path(missing_amenity)}']", count: 0
    assert_select "#recommendations-track a[href='#{sublet_listing_path(outside_window)}']", count: 0
    assert_select "#newest-track a[href='#{sublet_listing_path(missing_bedroom)}']"
    assert_select "input[name='recommendation_move_in'][value='06/12/2026']"
    assert_select "select[name='recommendation_bedrooms'] option[value='2'][selected]"
    assert_select "input[name='recommendation_amenities[]'][value='Gym'][checked]"
  end

  test "home recommendation filters show inline error for invalid date order" do
    get root_path(
      recommendation_move_in: "09/11/2026",
      recommendation_move_out: "06/12/2026"
    )

    assert_select "[data-recommendation-filter-error]", text: "Move-out date must be after move-in date."
    assert_select "#recommendations-track a.listing-card", count: 0
  end

  test "home page shows recently viewed listings after browsing listing pages" do
    user = User.create!(
      name: "Recent Viewer",
      email: "recent.viewer@u.northwestern.edu",
      active: true
    )
    first_listing = user.sublet_listings.create!(
      valid_listing_attributes.merge(
        title: "First Recently Viewed",
        available_from: Date.new(2026, 5, 24),
        available_until: Date.new(2026, 10, 3)
      )
    )
    second_listing = user.sublet_listings.create!(
      valid_listing_attributes.merge(
        title: "Second Recently Viewed",
        address: "910 Noyes St, Evanston, IL 60201",
        available_from: Date.new(2026, 6, 1),
        available_until: Date.new(2026, 9, 1)
      )
    )

    get root_path

    assert_select "#recently-viewed", count: 0

    get sublet_listing_path(first_listing)
    get sublet_listing_path(second_listing)
    get root_path

    assert_response :success
    assert_select "#recently-viewed-title", text: "Recently Viewed"
    assert_select "#recently-viewed-track a[href='#{sublet_listing_path(second_listing)}']"
    assert_select "#recently-viewed-track a[href='#{sublet_listing_path(first_listing)}']"
    assert_match(/Second Recently Viewed.*First Recently Viewed/m, response.body)
  end

  test "signed in navigation shows the current user and logout" do
    sign_in_with_firebase_email("student@u.northwestern.edu")

    get root_path

    assert_response :success
    assert_select "a[href='#{profile_path}']", text: "Profile", count: 1
    assert_select "form[action='#{session_path}'] button", text: "Log out"
    assert_select "a[data-login-trigger]", text: "Create a Posting", count: 0
    assert_select "a[href='#{post_sublet_path}']", text: "Create a Posting"
  end

  test "profile page is tailored to the signed in user" do
    sign_in_with_firebase_email("student@u.northwestern.edu")

    get profile_path

    assert_response :success
    assert_select "h1", text: "Test Student"
    assert_includes response.body, "student@u.northwestern.edu"
    assert_includes response.body, "Hi Test"
    assert_includes response.body, "Verified Northwestern student"
    assert_includes response.body, "Student / renter"
    assert_includes response.body, "Preferred Contact"
    assert_includes response.body, "Usually responds within 2 days"
    assert_select "a", text: "Report profile"
    assert_select "a[href='#{post_sublet_path}']", text: "Post a Sublet"
  end

  test "another user account page keeps the previous profile layout" do
    sign_in_with_firebase_email("student@u.northwestern.edu")

    get another_user_account_path

    assert_response :success
    assert_select "h1", text: "Test Student"
    assert_select ".profile-card"
    assert_select ".section-title", text: "Current Listings"
    assert_includes response.body, "student@u.northwestern.edu"
  end

  test "search results page links into listing and home" do
    get search_results_path

    assert_select "a[href='#{root_path}']", text: /NU[- ]Sublets/
    assert_select "a[href='#{saved_path}']", text: /Saved/
    assert_select "a[href='#{post_sublet_path}']", text: /Post Sublet/
  end

  test "saved page renders the saved listings shell" do
    get saved_path

    assert_select "h1", text: "Saved Sublets"
    assert_select "[data-favorite-listings]"
    assert_select "[data-favorites-empty]", text: /No saved sublets yet/
    assert_select "a[href='#{search_results_path}']", text: /Browse sublets/
    assert_includes response.body, "nuSublets.favoriteListings"
    assert_includes response.body, "#ed4956"
  end

  test "search results toolbar includes date filter controls" do
    get search_results_path("move-in": "06/12/2026", "move-out": "09/11/2026")

    assert_select "form[action='#{search_results_path}'][method='get'][data-search-filter-form]"
    assert_select "input[name='move-in'][value='06/12/2026']"
    assert_select "input[name='move-out'][value='09/11/2026']"
    assert_select "[data-date-toggle]", text: "Jun 12 2026"
    assert_select "[data-date-toggle]", text: "Sep 11 2026"
    assert_select "input[name='min_price']"
    assert_select "input[name='max_price']"
    assert_select "select[name='bedrooms']"
    assert_select "select[name='bathrooms']"
    assert_select "input[name='amenities[]'][value='Laundry']"
    assert_select "input[name='preferences[]'][value='Graduate student']"
    assert_includes response.body, "Please enter a move-in date"
    assert_includes response.body, "Please enter a move-out date"
    assert_includes response.body, "Please enter a move-in and a move-out date"
  end

  test "home page includes natural language search input" do
    get root_path

    assert_select "form[action='#{search_results_path}'][method='get'] input[name='natural_query'][type='search']"
  end

  test "search results preserves natural language query in the toolbar" do
    get search_results_path(natural_query: "furnished studio under $1200 near campus")

    assert_select "input[name='natural_query'][value='furnished studio under $1200 near campus']"
    assert_includes response.body, "Search: "
  end

  test "search results shows invalid date order in the inline filter error" do
    get search_results_path("move-in": "09/11/2026", "move-out": "06/12/2026")

    assert_select "[data-filter-error]", text: "Move-out date must be after move-in date."
    assert_select "[data-filter-error][hidden]", count: 0
    assert_select ".flash-error", count: 0
  end

  test "search results filters by price space amenities and preferences" do
    user = User.create!(
      name: "Filter Owner",
      email: "filter.owner@u.northwestern.edu",
      active: true
    )
    matching_listing = user.sublet_listings.create!(
      valid_listing_attributes.merge(
        title: "Amenity Rich Match",
        price: 950,
        bedrooms: 1,
        bathrooms: 1,
        utilities_included: true,
        amenities: [ "Laundry", "Gym", "Utilities included" ],
        preferences: [ "Graduate student", "Quiet" ],
        available_from: Date.new(2026, 5, 24),
        available_until: Date.new(2026, 10, 3)
      )
    )
    user.sublet_listings.create!(
      valid_listing_attributes.merge(
        title: "Missing Gym",
        price: 900,
        bedrooms: 1,
        bathrooms: 1,
        amenities: [ "Laundry" ],
        preferences: [ "Graduate student", "Quiet" ],
        available_from: Date.new(2026, 5, 24),
        available_until: Date.new(2026, 10, 3)
      )
    )
    user.sublet_listings.create!(
      valid_listing_attributes.merge(
        title: "Too Expensive Filter",
        price: 1500,
        bedrooms: 1,
        bathrooms: 1,
        amenities: [ "Laundry", "Gym", "Utilities included" ],
        preferences: [ "Graduate student", "Quiet" ],
        available_from: Date.new(2026, 5, 24),
        available_until: Date.new(2026, 10, 3)
      )
    )

    get search_results_path(
      "move-in": "06/12/2026",
      "move-out": "09/11/2026",
      min_price: "800",
      max_price: "1200",
      bedrooms: "1",
      bathrooms: "1",
      amenities: [ "Laundry", "Gym" ],
      preferences: [ "Graduate student" ]
    )

    assert_select "a[href='#{sublet_listing_path(matching_listing)}']", text: /Amenity Rich Match/
    assert_no_match "Missing Gym", response.body
    assert_no_match "Too Expensive Filter", response.body
    assert_select "input[name='amenities[]'][value='Gym'][checked]"
    assert_select "input[name='preferences[]'][value='Graduate student'][checked]"
  end

  test "natural language search filters listings through existing search behavior" do
    user = User.create!(
      name: "Natural Search Owner",
      email: "natural.search.owner@u.northwestern.edu",
      active: true
    )
    matching_listing = user.sublet_listings.create!(
      valid_listing_attributes.merge(
        title: "Natural Search Match",
        price: 950,
        bedrooms: 0,
        bathrooms: 1,
        furnished: true,
        amenities: [ "Furnished", "Laundry" ],
        available_from: Date.new(2026, 5, 24),
        available_until: Date.new(2026, 10, 3)
      )
    )
    user.sublet_listings.create!(
      valid_listing_attributes.merge(
        title: "Too Expensive Natural Search",
        price: 1500,
        bedrooms: 0,
        bathrooms: 1,
        furnished: true,
        amenities: [ "Furnished", "Laundry" ],
        available_from: Date.new(2026, 5, 24),
        available_until: Date.new(2026, 10, 3)
      )
    )

    get search_results_path(natural_query: "furnished studio under $1200 with laundry")

    assert_select "a[href='#{sublet_listing_path(matching_listing)}']", text: /Natural Search Match/
    assert_no_match "Too Expensive Natural Search", response.body
    assert_select "select[name='bedrooms'] option[value='0'][selected]"
    assert_select "input[name='amenities[]'][value='Laundry'][checked]"
  end

  test "manual filters override natural language parsed filters" do
    user = User.create!(
      name: "Override Owner",
      email: "override.owner@u.northwestern.edu",
      active: true
    )
    matching_listing = user.sublet_listings.create!(
      valid_listing_attributes.merge(
        title: "Manual Override Match",
        price: 1400,
        bedrooms: 1,
        bathrooms: 1,
        furnished: true,
        amenities: [ "Furnished" ],
        available_from: Date.new(2026, 5, 24),
        available_until: Date.new(2026, 10, 3)
      )
    )

    get search_results_path(
      natural_query: "furnished 1 bed under $1000",
      max_price: "1500"
    )

    assert_select "a[href='#{sublet_listing_path(matching_listing)}']", text: /Manual Override Match/
    assert_select "input[name='max_price'][value='1500']"
  end

  test "search results only include listings covering the requested dates" do
    user = User.create!(
      name: "Search Owner",
      email: "search.owner@u.northwestern.edu",
      active: true
    )
    matching_listing = user.sublet_listings.create!(
      valid_listing_attributes.merge(
        title: "Covers Full Stay",
        available_from: Date.new(2026, 5, 24),
        available_until: Date.new(2026, 10, 3)
      )
    )
    user.sublet_listings.create!(
      valid_listing_attributes.merge(
        title: "Ends Too Early",
        available_from: Date.new(2026, 5, 24),
        available_until: Date.new(2026, 8, 15)
      )
    )
    user.sublet_listings.create!(
      valid_listing_attributes.merge(
        title: "Starts Too Late",
        available_from: Date.new(2026, 7, 1),
        available_until: Date.new(2026, 10, 3)
      )
    )

    get search_results_path("move-in": "06/12/2026", "move-out": "09/11/2026")

    assert_select "a[href='#{sublet_listing_path(matching_listing)}']", text: /Covers Full Stay/
    assert_no_match "Ends Too Early", response.body
    assert_no_match "Starts Too Late", response.body
  end

  test "search results map shows price pins and grouped count pins" do
    user = User.create!(
      name: "Map Owner",
      email: "map.owner@u.northwestern.edu",
      active: true
    )
    single_listing = user.sublet_listings.create!(
      valid_listing_attributes.merge(
        title: "Single Address Listing",
        address: "820 Noyes St, Evanston, IL 60201",
        price: 850,
        available_from: Date.new(2026, 5, 24),
        available_until: Date.new(2026, 10, 3)
      )
    )
    grouped_listing = user.sublet_listings.create!(
      valid_listing_attributes.merge(
        title: "Apartment Option A",
        address: "1570 Oak Ave, Apt 1, Evanston, IL 60201",
        price: 1100,
        available_from: Date.new(2026, 5, 24),
        available_until: Date.new(2026, 10, 3)
      )
    )
    user.sublet_listings.create!(
      valid_listing_attributes.merge(
        title: "Apartment Option B",
        address: "1570 Oak Ave, Apt 2, Evanston, IL 60201",
        price: 1200,
        available_from: Date.new(2026, 5, 24),
        available_until: Date.new(2026, 10, 3)
      )
    )

    get search_results_path("move-in": "06/12/2026", "move-out": "09/11/2026")

    assert_select "[data-map-stage]"
    assert_select "[data-map-pin]", count: 2
    assert_select "[data-map-pin]", text: "$850"
    assert_select "[data-map-pin].count-pin", text: "2"
    assert_select "[data-map-popup] a[href='#{sublet_listing_path(single_listing)}']", text: /Single Address Listing/
    assert_select "[data-map-popup] a[href='#{sublet_listing_path(grouped_listing)}']", text: /Apartment Option A/
  end

  test "listing page shows the selected listing dates" do
    user = User.create!(
      name: "Detail Owner",
      email: "detail.owner@u.northwestern.edu",
      profile_photo_url: "https://example.com/detail-owner.jpg",
      active: true
    )
    listing = user.sublet_listings.create!(
      valid_listing_attributes.merge(
        title: "Detail Date Match",
        available_from: Date.new(2026, 5, 24),
        available_until: Date.new(2026, 10, 3)
      )
    )

    get sublet_listing_path(listing)

    assert_response :success
    assert_includes response.body, "May 24, 2026"
    assert_includes response.body, "October 3, 2026"
    assert_includes response.body, "Detail Date Match"
    assert_select "a[href='#{search_results_path}']", text: /Back to search results/
    assert_select "a[href='#{user_profile_path(user)}']", text: /Detail Owner/
    assert_select "a[href='#{user_profile_path(user)}'] img.host-avatar[alt='Detail Owner profile photo'][src='https://example.com/detail-owner.jpg']"
  end

  test "listing page displays public questions and host answers" do
    host = User.create!(
      name: "Question Host",
      email: "question.host@u.northwestern.edu",
      active: true
    )
    renter = User.create!(
      name: "Question Renter",
      email: "question.renter@u.northwestern.edu",
      active: true
    )
    listing = host.sublet_listings.create!(
      valid_listing_attributes.merge(
        title: "Question Board Listing",
        available_from: Date.new(2026, 5, 24),
        available_until: Date.new(2026, 10, 3)
      )
    )
    listing.listing_questions.create!(
      user: renter,
      body: "Are utilities included?",
      answer: "Yes, utilities are included.",
      answered_at: Time.current
    )

    get sublet_listing_path(listing)

    assert_response :success
    assert_select "#questions", text: /Questions & Answers/
    assert_includes response.body, "Are utilities included?"
    assert_includes response.body, "Yes, utilities are included."
    assert_includes response.body, "Asked by Question Renter"
    assert_includes response.body, "Answered by Question Host"
  end

  test "signed out users cannot post listing questions" do
    host = User.create!(name: "Question Host", email: "signedout.host@u.northwestern.edu", active: true)
    listing = host.sublet_listings.create!(
      valid_listing_attributes.merge(
        title: "Signed Out Question Listing",
        available_from: Date.new(2026, 5, 24),
        available_until: Date.new(2026, 10, 3)
      )
    )

    assert_no_difference("ListingQuestion.count") do
      post sublet_listing_questions_path(listing), params: { listing_question: { body: "Is this available?" } }
    end

    assert_redirected_to login_path
  end

  test "logged in non owner can ask a listing question" do
    host = User.create!(name: "Question Host", email: "ask.host@u.northwestern.edu", active: true)
    listing = host.sublet_listings.create!(
      valid_listing_attributes.merge(
        title: "Askable Listing",
        available_from: Date.new(2026, 5, 24),
        available_until: Date.new(2026, 10, 3)
      )
    )
    sign_in_with_firebase_email("ask.renter@u.northwestern.edu")

    assert_difference("ListingQuestion.count", 1) do
      post sublet_listing_questions_path(listing), params: { listing_question: { body: "Is parking available?" } }
    end

    assert_redirected_to sublet_listing_path(listing, anchor: "questions")
    assert_equal "Is parking available?", ListingQuestion.order(:created_at).last.body
  end

  test "listing owner cannot ask a question on their own listing" do
    host = User.create!(name: "Question Host", email: "owner.ask.host@u.northwestern.edu", active: true)
    listing = host.sublet_listings.create!(
      valid_listing_attributes.merge(
        title: "Owner Question Listing",
        available_from: Date.new(2026, 5, 24),
        available_until: Date.new(2026, 10, 3)
      )
    )
    sign_in_with_firebase_email(host.email)

    assert_no_difference("ListingQuestion.count") do
      post sublet_listing_questions_path(listing), params: { listing_question: { body: "Can I ask myself?" } }
    end

    assert_redirected_to sublet_listing_path(listing)
  end

  test "listing owner can answer a question but unrelated user cannot" do
    host = User.create!(name: "Answer Host", email: "answer.host@u.northwestern.edu", active: true)
    renter = User.create!(name: "Answer Renter", email: "answer.renter@u.northwestern.edu", active: true)
    listing = host.sublet_listings.create!(
      valid_listing_attributes.merge(
        title: "Answerable Listing",
        available_from: Date.new(2026, 5, 24),
        available_until: Date.new(2026, 10, 3)
      )
    )
    question = listing.listing_questions.create!(user: renter, body: "Is the lease flexible?")

    sign_in_with_firebase_email("unrelated.answer@u.northwestern.edu")
    patch listing_question_path(question), params: { listing_question: { answer: "Not my listing." } }

    assert_redirected_to sublet_listing_path(listing)
    assert_nil question.reload.answer

    sign_in_with_firebase_email(host.email)
    patch listing_question_path(question), params: { listing_question: { answer: "Yes, dates are flexible." } }

    assert_redirected_to sublet_listing_path(listing, anchor: "questions")
    assert_equal "Yes, dates are flexible.", question.reload.answer
    assert_not_nil question.answered_at
  end

  test "question author and listing owner can delete questions" do
    host = User.create!(name: "Delete Host", email: "delete.host@u.northwestern.edu", active: true)
    renter = User.create!(name: "Delete Renter", email: "delete.renter@u.northwestern.edu", active: true)
    listing = host.sublet_listings.create!(
      valid_listing_attributes.merge(
        title: "Deletable Listing",
        available_from: Date.new(2026, 5, 24),
        available_until: Date.new(2026, 10, 3)
      )
    )
    author_question = listing.listing_questions.create!(user: renter, body: "Can I delete this?")
    host_question = listing.listing_questions.create!(user: renter, body: "Can host delete this?")

    sign_in_with_firebase_email(renter.email)
    assert_difference("ListingQuestion.count", -1) do
      delete listing_question_path(author_question)
    end

    sign_in_with_firebase_email(host.email)
    assert_difference("ListingQuestion.count", -1) do
      delete listing_question_path(host_question)
    end
  end

  test "unrelated user cannot delete another users listing question" do
    host = User.create!(name: "Guard Host", email: "guard.host@u.northwestern.edu", active: true)
    renter = User.create!(name: "Guard Renter", email: "guard.renter@u.northwestern.edu", active: true)
    listing = host.sublet_listings.create!(
      valid_listing_attributes.merge(
        title: "Guarded Listing",
        available_from: Date.new(2026, 5, 24),
        available_until: Date.new(2026, 10, 3)
      )
    )
    question = listing.listing_questions.create!(user: renter, body: "Can anyone delete this?")

    sign_in_with_firebase_email("unrelated.delete@u.northwestern.edu")

    assert_no_difference("ListingQuestion.count") do
      delete listing_question_path(question)
    end

    assert_redirected_to sublet_listing_path(listing)
  end

  test "browse listing avatar links to the listing owner's public profile" do
    user = User.create!(
      name: "Profile Owner",
      email: "profile.owner@u.northwestern.edu",
      profile_photo_url: "https://example.com/profile-owner.jpg",
      confirmed_at: Time.current,
      active: true
    )
    listing = user.sublet_listings.create!(
      valid_listing_attributes.merge(
        title: "Owner Profile Link",
        available_from: Date.new(2026, 5, 24),
        available_until: Date.new(2026, 10, 3)
      )
    )

    get search_results_path("move-in": "06/12/2026", "move-out": "09/11/2026")

    assert_response :success
    assert_select "a[href='#{sublet_listing_path(listing)}']", text: /Owner Profile Link/
    assert_select "a[href='#{user_profile_path(user)}'][aria-label=?]", "View Profile Owner's profile"
    assert_select "a[href='#{user_profile_path(user)}'] img.listing-avatar-image[alt='Profile Owner profile photo'][src='https://example.com/profile-owner.jpg']"

    get user_profile_path(user)

    assert_response :success
    assert_select "h1", text: "Profile Owner"
    assert_select "img.profile-avatar[alt='Profile Owner profile avatar'][src='https://example.com/profile-owner.jpg']"
    assert_includes response.body, "Verified Northwestern student"
    assert_select "a[href='#{sublet_listing_path(listing)}']", text: /Owner Profile Link/
    assert_select "a[href='#{sublet_listing_path(listing)}'] img.listing-avatar[alt='Profile Owner listing avatar'][src='https://example.com/profile-owner.jpg']"
  end

  test "post sublet page uses the submit endpoint" do
    get post_sublet_path

    assert_select "form[action='#{submit_sublet_path}'][method='post']"
    assert_select "input[type='file'][name='photos[]'][accept='image/png,image/jpeg,image/webp'][multiple]"
    assert_includes response.body, "Upload up to 5 photos. PNG, JPG, or WebP only. 5 MB max per photo."
  end

  private

  def valid_sublet_post_params
    {
      title: "Sunny Room Near Campus",
      description: "Clean furnished room within walking distance of campus.",
      bedrooms: "1",
      bathrooms: "1",
      "street-address" => "820 Noyes St",
      "city" => "Evanston",
      "state" => "IL",
      "zip-code" => "60201",
      "start-date" => "06/12/2026",
      "end-date" => "09/11/2026",
      price: "850",
      furnished: "1",
      utilities_included: "1",
      amenities: [ "Laundry", "Gym" ],
      preferences: [ "Graduate student", "Quiet" ]
    }
  end

  def valid_listing_attributes
    {
      description: "Clean furnished room within walking distance of campus.",
      price: 850,
      address: "820 Noyes St, Evanston, IL 60201",
      bedrooms: 1,
      bathrooms: 1,
      furnished: true,
      pets_allowed: false,
      utilities_included: true
    }
  end

  def sign_in_with_firebase_email(email)
    verifier = Class.new do
      define_method(:verify) do |_id_token|
        {
          "email" => email,
          "email_verified" => true,
          "name" => "Test Student"
        }
      end
    end.new

    original_new = FirebaseTokenVerifier.method(:new)
    FirebaseTokenVerifier.define_singleton_method(:new) { |*| verifier }

    post session_path, params: { id_token: "firebase-token" }, as: :json
  ensure
    FirebaseTokenVerifier.define_singleton_method(:new) { |*args, **kwargs| original_new.call(*args, **kwargs) }
  end

  def uploaded_test_file(filename, content_type, content)
    file = Tempfile.new([ File.basename(filename, ".*"), File.extname(filename) ], binmode: true)
    file.write(content)
    file.rewind

    Rack::Test::UploadedFile.new(file.path, content_type, original_filename: filename)
  end
end
