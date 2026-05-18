require "test_helper"

class PagesFlowTest < ActionDispatch::IntegrationTest
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

  test "home page links to the other product views" do
    get root_path

    assert_select "a[href='#{search_results_path}']", text: /Search/
    assert_select "a[href='#{saved_path}']", text: /Saved/
    assert_select "a[href='#{post_sublet_path}']", text: /Post Sublet|Create a Posting/
    assert_select "a[href='#{login_path}']", text: /Log in/
    assert_select "a[href='#{listing_path}']"
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

  test "browse listing avatar links to the listing owner's public profile" do
    user = User.create!(
      name: "Profile Owner",
      email: "profile.owner@u.northwestern.edu",
      profile_photo_url: "https://example.com/profile-owner.jpg",
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
end
