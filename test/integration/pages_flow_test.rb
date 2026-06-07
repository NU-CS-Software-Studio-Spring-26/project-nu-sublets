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

  test "listing page requires login" do
    get listing_path

    assert_redirected_to login_path
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

  test "community guidelines page is reachable from the footer" do
    get root_path

    assert_select "footer a[href='#{community_guidelines_path}']", text: "Community Guidelines"

    get community_guidelines_path

    assert_response :success
    assert_select "h1", text: "Community Guidelines"
    assert_select "h2", text: "Post responsibly"
    assert_includes response.body, "Post only one active sublet listing at a time."
    assert_includes response.body, "Do not post fake, duplicate, misleading, or scam listings."
    assert_includes response.body, "NU Sublets helps connect students, but it does not provide legal, financial, housing, or safety advice"
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

  test "logged out home page locks browse listing sections" do
    get root_path

    assert_response :success
    assert_select ".listing-access-lock__prompt", text: /Please log in to view sublet listings/
    assert_select ".listing-access-lock__content[inert]"
    assert_select "a.listing-access-lock__button[href='#{login_path}']", text: "Log in"
    assert_select "#recommendations-track a.listing-card"
    assert_select "[data-compare-tray]", count: 0
  end

  test "logged out search results are locked behind login" do
    get search_results_path

    assert_response :success
    assert_select ".listing-access-lock__prompt", text: /Please log in to search and view sublet listings/
    assert_select ".listing-access-lock__content[inert]"
    assert_select "a.listing-access-lock__button[href='#{login_path}']", text: "Log in"
    assert_select "[data-compare-tray]", count: 0
  end

  test "logged out search PDF export redirects to login" do
    get search_results_path(format: :pdf)

    assert_redirected_to login_path
  end

  test "logged out saved page hides saved listing content" do
    get saved_path

    assert_response :success
    assert_select ".listing-access-lock__prompt", text: /Please log in to view saved listings/
    assert_select ".listing-access-lock__content[inert]"
    assert_select "[data-favorite-listings]", count: 0
    refute_includes response.body, "nuSublets.favoriteListings"
  end

  test "logged out post sublet page locks the form" do
    get post_sublet_path

    assert_response :success
    assert_select ".listing-access-lock__prompt", text: /Please log in with your Northwestern account to post a sublet/
    assert_select ".listing-access-lock__content[inert] form[action='#{submit_sublet_path}']"
    assert_select ".post-card button[type='submit']", count: 0
    assert_select "button[data-login-trigger]", text: "Post Sublet"
  end

  test "logged in post sublet form submits to an app endpoint" do
    sign_in_with_firebase_email("student@u.northwestern.edu")

    assert_difference("SubletListing.count", 1) do
      post submit_sublet_path, params: valid_sublet_post_params
    end

    listing = SubletListing.order(:created_at).last

    assert_equal Date.new(2026, 6, 12), listing.available_from
    assert_equal Date.new(2026, 9, 11), listing.available_until
    assert_equal 850, listing.price.to_i
    assert_equal [ "Laundry", "Gym" ], listing.amenities
    assert_equal [ "Graduate student", "Quiet" ], listing.preferences
    assert_redirected_to profile_path
    follow_redirect!
    assert_response :success
    assert_select ".profile-alert.success", text: "Your sublet listing was posted successfully."
    assert_select ".profile-listing-card a[href='#{sublet_listing_path(listing)}']"
    assert_includes response.body, "820 Noyes St, Evanston, IL, 60201"
  end

  test "post sublet accepts comma formatted rent and all amenities" do
    sign_in_with_firebase_email("comma.rent.poster@u.northwestern.edu")

    assert_difference("SubletListing.count", 1) do
      post submit_sublet_path, params: valid_sublet_post_params.merge(
        price: "1,200",
        amenities: SubletListing::AMENITY_OPTIONS
      )
    end

    listing = SubletListing.order(:created_at).last

    assert_equal 1200, listing.price.to_i
    assert_equal SubletListing::AMENITY_OPTIONS, listing.amenities
  end

  test "post sublet page warns when signed in user already has an active listing" do
    sign_in_with_firebase_email("active.poster@u.northwestern.edu")
    user = User.find_by!(email: "active.poster@u.northwestern.edu")
    listing = user.sublet_listings.create!(
      valid_listing_attributes.merge(
        title: "Current Active Listing",
        available_from: Date.new(2026, 6, 12),
        available_until: Date.new(2026, 9, 11)
      )
    )

    get post_sublet_path

    assert_response :success
    assert_includes response.body, SubletListing::ACTIVE_LISTING_LIMIT_MESSAGE
    assert_select "a[href='#{sublet_listing_path(listing)}']", text: "View current listing"
    assert_select "a[href='#{profile_path}']", text: "Manage listings"
    assert_select "form.post-card", count: 0
  end

  test "signed in user with active listing cannot create a second active listing by direct post" do
    sign_in_with_firebase_email("duplicate.poster@u.northwestern.edu")
    user = User.find_by!(email: "duplicate.poster@u.northwestern.edu")
    user.sublet_listings.create!(
      valid_listing_attributes.merge(
        title: "Existing Active Listing",
        available_from: Date.new(2026, 6, 12),
        available_until: Date.new(2026, 9, 11)
      )
    )

    assert_no_difference("SubletListing.count") do
      post submit_sublet_path, params: valid_sublet_post_params.merge("street-address" => "910 Noyes St")
    end

    assert_response :unprocessable_entity
    assert_includes response.body, SubletListing::ACTIVE_LISTING_LIMIT_MESSAGE
    assert_select "form.post-card", count: 0
  end

  test "expired listing does not block posting a new active listing" do
    sign_in_with_firebase_email("expired.poster@u.northwestern.edu")
    user = User.find_by!(email: "expired.poster@u.northwestern.edu")
    expired_listing = user.sublet_listings.create!(
      valid_listing_attributes.merge(
        title: "Expired Listing",
        available_from: Date.new(2026, 6, 12),
        available_until: Date.new(2026, 9, 11)
      )
    )
    expired_listing.update_columns(
      available_from: Date.current - 60.days,
      available_until: Date.current - 1.day
    )

    assert_difference("SubletListing.count", 1) do
      post submit_sublet_path, params: valid_sublet_post_params.merge("street-address" => "910 Noyes St")
    end

    assert_redirected_to profile_path
  end

  test "owner can update their existing active listing" do
    sign_in_with_firebase_email("edit.active.poster@u.northwestern.edu")
    user = User.find_by!(email: "edit.active.poster@u.northwestern.edu")
    listing = user.sublet_listings.create!(
      valid_listing_attributes.merge(
        title: "Editable Active Listing",
        available_from: Date.new(2026, 6, 12),
        available_until: Date.new(2026, 9, 11)
      )
    )

    patch sublet_listing_path(listing), params: {
      sublet_listing: {
        title: "Edited Active Listing",
        description: listing.description,
        price: 975,
        address: listing.address,
        bedrooms: listing.bedrooms,
        bathrooms: listing.bathrooms,
        available_from: listing.available_from,
        available_until: listing.available_until,
        furnished: listing.furnished,
        pets_allowed: listing.pets_allowed,
        utilities_included: listing.utilities_included
      }
    }

    assert_redirected_to sublet_listing_path(listing)
    listing.reload
    assert_equal "Edited Active Listing", listing.title
    assert_equal 975, listing.price.to_i
  end

  test "post sublet blocks profanity in direct server submission" do
    sign_in_with_firebase_email("profanity.poster@u.northwestern.edu")

    assert_no_difference("SubletListing.count") do
      post submit_sublet_path, params: valid_sublet_post_params.merge(
        description: "Clean furnished room, but this sentence says shit."
      )
    end

    assert_response :unprocessable_entity
    assert_includes response.body, ProfanityFilter::ERROR_MESSAGE
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
    assert_select "input[name='city'][value='Evanston']"
    assert_select "input[name='state'][value='IL']"
    assert_select "input[name='zip-code'][value='60201']"
    assert_select "input[name='start-date'][value='06/12/2026']"
    assert_select "input[name='end-date'][value='09/11/2026']"
    assert_select "input[name='price'][value='850']"
    assert_select "select[name='bedrooms'] option[value='1'][selected]"
    assert_select "select[name='bathrooms'] option[value='1'][selected]"
    assert_select "textarea[name='description']", text: "Clean furnished room within walking distance of campus."
    assert_select "input[type='number'][name='bedrooms']", count: 0
    assert_select "input[type='number'][name='bathrooms']", count: 0
    assert_select "input[name='school-email']", count: 0
    assert_includes response.body, 'const initialAmenities = ["Laundry","Gym"]'
    assert_includes response.body, 'const initialPreferences = ["Graduate student","Quiet"]'
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

  test "home page includes category sublet carousels" do
    get root_path

    assert_response :success
    assert_select "#budget-friendly-title", text: "Budget-Friendly Finds"
    assert_select "#budget-friendly-track[data-carousel-track]"
    assert_select "#furnished-ready-title", text: "Furnished & Move-In Ready"
    assert_select "#furnished-ready-track[data-carousel-track]"
    assert_select "#pet-friendly-title", text: "Pet-Friendly Picks"
    assert_select "#pet-friendly-track[data-carousel-track]"
  end

  test "home category carousels use matching database listings" do
    user = User.create!(
      name: "Carousel Owner",
      email: "carousel.owner@u.northwestern.edu",
      active: true
    )
    budget_listing = user.sublet_listings.create!(
      valid_listing_attributes.merge(
        title: "Affordable Carousel Match",
        price: 925,
        available_from: Date.new(2026, 5, 24),
        available_until: Date.new(2026, 10, 3)
      )
    )
    furnished_listing = listing_owner("carousel-furnished").sublet_listings.create!(
      valid_listing_attributes.merge(
        title: "Furnished Carousel Match",
        address: "910 Noyes St, Evanston, IL 60201",
        price: 1250,
        furnished: true,
        available_from: Date.new(2026, 5, 24),
        available_until: Date.new(2026, 10, 3)
      )
    )
    pet_listing = listing_owner("carousel-pet").sublet_listings.create!(
      valid_listing_attributes.merge(
        title: "Pet Carousel Match",
        address: "1722 Oak Ave, Evanston, IL 60201",
        price: 1350,
        pets_allowed: true,
        available_from: Date.new(2026, 5, 24),
        available_until: Date.new(2026, 10, 3)
      )
    )

    get root_path

    assert_response :success
    assert_select "#budget-friendly-track a[href='#{sublet_listing_path(budget_listing)}']", text: /Affordable Carousel Match/
    assert_select "#furnished-ready-track a[href='#{sublet_listing_path(furnished_listing)}']", text: /Furnished Carousel Match/
    assert_select "#pet-friendly-track a[href='#{sublet_listing_path(pet_listing)}']", text: /Pet Carousel Match/
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

    assert_select "form.search-card[action='#{search_results_path}'][method='get'] input[name='natural_query'][type='search']"
    assert_select "form.search-card input[name='move-in']", count: 0
    assert_select "form.search-card input[name='move-out']", count: 0
    assert_select "form[action='#{root_path(anchor: "recommendations")}'][method='get'][aria-label='Filter recommended sublets']"
    assert_select "form[aria-label='Filter recommended sublets'] [data-date-picker] input[name='recommendation_move_in'][data-date-input]"
    assert_select "form[aria-label='Filter recommended sublets'] [data-date-picker] input[name='recommendation_move_out'][data-date-input]"
    assert_select "form[aria-label='Filter recommended sublets'] [data-date-toggle]", count: 2
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
    missing_bedroom = listing_owner("recommendation-bedroom").sublet_listings.create!(
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
    missing_amenity = listing_owner("recommendation-amenity").sublet_listings.create!(
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
    outside_window = listing_owner("recommendation-window").sublet_listings.create!(
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
    second_listing = listing_owner("recent-second").sublet_listings.create!(
      valid_listing_attributes.merge(
        title: "Second Recently Viewed",
        address: "910 Noyes St, Evanston, IL 60201",
        available_from: Date.new(2026, 6, 1),
        available_until: Date.new(2026, 9, 1)
      )
    )
    sign_in_with_firebase_email("student@u.northwestern.edu")

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
    assert_select "a[href='#{conversations_path}']", text: "Chat", count: 1
    assert_select "form[action='#{session_path}'] button", text: "Log out"
    assert_select "a[data-login-trigger]", text: "Create a Posting", count: 0
    assert_select "a.cta-button[href='#{post_sublet_path}']", text: "Create a Posting"
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
    assert_select "form#profile-settings-form[data-profanity-check]"
    assert_select "form#delete-account-form[action='#{profile_path}'][method='post']"
    assert_select "form#delete-account-form input[name='_method'][value='delete']", visible: false
    assert_select "button.delete-account-button[form='delete-account-form']", text: "Delete Account"
    assert_select "textarea[name='user[bio]'][data-profanity-field]"
  end

  test "profile post listing button reflects active listing status" do
    sign_in_with_firebase_email("profile.active.poster@u.northwestern.edu")
    user = User.find_by!(email: "profile.active.poster@u.northwestern.edu")

    get profile_path

    assert_select "a.profile-primary-link[href='#{post_sublet_path}']", text: "Post a Listing"
    assert_select ".profile-primary-link.is-disabled", count: 0

    listing = user.sublet_listings.create!(
      valid_listing_attributes.merge(
        title: "Profile Active Listing",
        available_from: Date.new(2026, 6, 1),
        available_until: Date.new(2026, 9, 1)
      )
    )

    get profile_path

    assert_select ".profile-primary-link.is-disabled[aria-disabled='true']", text: "Post a Listing"
    assert_select "a.profile-primary-link[href='#{post_sublet_path}']", count: 0
    assert_includes response.body, "You can only have one active sublet listing at a time."
    assert_select ".profile-listing-card"
    assert_select ".listing-card-menu-link[href='#{sublet_listing_path(listing)}']", text: "Edit listing"
    assert_select "form[action='#{sublet_listing_path(listing)}'][method='post'] button.listing-card-menu-delete", text: "Delete listing"
    assert_select "form[action='#{sublet_listing_path(listing)}'][method='post'] button.listing-card-menu-delete[data-turbo-confirm='Are you sure you want to delete this listing?']"
    assert_select "form[action='#{sublet_listing_path(listing)}'][data-turbo-confirm='Are you sure you want to delete this listing?']"
    assert_select "form[action='#{sublet_listing_path(listing)}'][onsubmit=\"return !!window.Turbo || confirm('Are you sure you want to delete this listing?');\"]"
    assert_select "form[action='#{sublet_listing_path(listing)}'] input[name='_method'][value='delete']", visible: false
    assert_includes response.body, "Are you sure you want to delete this listing?"
  end

  test "deleting a listing removes it from profile listings" do
    sign_in_with_firebase_email("profile.delete.owner@u.northwestern.edu")
    user = User.find_by!(email: "profile.delete.owner@u.northwestern.edu")
    listing = user.sublet_listings.create!(
      valid_listing_attributes.merge(
        title: "Profile Delete Listing",
        available_from: Date.new(2026, 6, 1),
        available_until: Date.new(2026, 9, 1)
      )
    )

    get profile_path
    assert_select "a[href='#{sublet_listing_path(listing)}']"

    assert_difference("SubletListing.count", -1) do
      delete sublet_listing_path(listing)
    end

    assert_redirected_to profile_path
    follow_redirect!

    assert_response :success
    assert_select ".profile-alert.success", text: "Listing deleted."
    assert_select "a[href='#{sublet_listing_path(listing)}']", count: 0
    assert_select "a.profile-primary-link[href='#{post_sublet_path}']", text: "Post a Listing"
  end

  test "delete account removes the signed in user and their owned data" do
    sign_in_with_firebase_email("delete.me@u.northwestern.edu")
    user = User.find_by!(email: "delete.me@u.northwestern.edu")
    other_user = User.create!(
      name: "Delete Flow Renter",
      email: "delete.flow.renter@u.northwestern.edu",
      confirmed_at: Time.current,
      active: true
    )
    listing = user.sublet_listings.create!(
      valid_listing_attributes.merge(
        title: "Delete Account Listing",
        available_from: Date.new(2026, 6, 1),
        available_until: Date.new(2026, 9, 1)
      )
    )
    conversation = Conversation.between(user, other_user, listing: listing)
    conversation.save!
    conversation.messages.create!(sender: user, body: "Is the account delete flow working?")

    assert_difference("User.count", -1) do
      assert_difference("SubletListing.count", -1) do
        assert_difference("Conversation.count", -1) do
          assert_difference("Message.count", -1) do
            delete profile_path
          end
        end
      end
    end

    assert_redirected_to root_path
    assert_nil User.find_by(email: "delete.me@u.northwestern.edu")

    get profile_path

    assert_redirected_to login_path
  end

  test "profile update blocks profanity in direct server submission" do
    email = "profile.profanity.post@u.northwestern.edu"
    sign_in_with_firebase_email(email)

    patch profile_path, params: {
      user: {
        name: "Test Student",
        email: email,
        bio: "This profile says shit."
      }
    }

    assert_response :unprocessable_entity
    assert_includes response.body, ProfanityFilter::ERROR_MESSAGE
    assert_nil User.find_by!(email: email).bio
  end

  test "another user account page keeps the previous profile layout" do
    sign_in_with_firebase_email("student@u.northwestern.edu")

    get another_user_account_path

    assert_response :success
    assert_select "h1", text: "Test Student"
    assert_select ".profile-card"
    assert_select ".section-title", text: "Current Listings"
    assert_includes response.body, "Hidden by profile setting"
    assert_not_includes response.body, "student@u.northwestern.edu"
  end

  test "search results page links into listing and home" do
    get search_results_path

    assert_select "a[href='#{root_path}']", text: /NU[- ]Sublets/
    assert_select "a[href='#{saved_path}']", text: /Saved/
    assert_select "a[href='#{post_sublet_path}']", text: /Post Sublet/
  end

  test "search results clears skeleton state before navigation cache restoration" do
    get search_results_path

    assert_response :success
    assert_includes response.body, "const clearSkeletons = () =>"
    assert_includes response.body, 'document.addEventListener("turbo:before-cache", clearSkeletons)'
    assert_includes response.body, 'document.addEventListener("turbo:load", clearSkeletons)'
    assert_includes response.body, 'document.addEventListener("turbo:render", clearSkeletons)'
    assert_includes response.body, 'window.addEventListener("pageshow", clearSkeletons)'
    assert_includes response.body, "window.clearTimeout(pendingSkeletonTimer)"
    refute_includes response.body, 'window.addEventListener("beforeunload", showSkeletons)'
  end

  test "browse and search pages expose compare listing data and tray" do
    sign_in_with_firebase_email("student@u.northwestern.edu")
    user = User.create!(
      name: "Compare Owner",
      email: "compare.owner@u.northwestern.edu",
      active: true
    )
    listing = user.sublet_listings.create!(
      valid_listing_attributes.merge(
        title: "Compare Ready Listing",
        pets_allowed: true,
        utilities_included: true,
        amenities: [ "Laundry", "Parking" ],
        available_from: Date.new(2026, 6, 12),
        available_until: Date.new(2026, 9, 11)
      )
    )

    get root_path

    assert_response :success
    assert_select "[data-compare-tray]"
    assert_select "[data-compare-modal]"
    assert_select "a[href='#{sublet_listing_path(listing)}'][data-compare-listing]"
    assert_includes response.body, "nuSublets.compareListings"
    assert_includes response.body, "You can compare up to 3 listings at a time."
    assert_includes response.body, "table-layout: fixed"
    assert_includes response.body, "<colgroup>"
    assert_includes response.body, "Utilities included"

    get search_results_path

    assert_response :success
    assert_select "article.listing-card[data-compare-listing]"
    assert_select "a[href='#{sublet_listing_path(listing)}']", text: /Compare Ready Listing/
  end

  test "saved page renders the saved listings shell" do
    sign_in_with_firebase_email("student@u.northwestern.edu")

    get saved_path

    assert_select "h1", text: "Saved Sublets"
    assert_select "[data-saved-grid]"
    assert_select "[data-saved-pagination]"
    assert_select "[data-saved-per-page]"
    assert_select "[data-favorites-empty]", text: /No saved sublets yet/
    assert_select "a[href='#{search_results_path}']", text: /Browse sublets/
    assert_includes response.body, "nuSublets.favoriteListings"
    assert_includes response.body, "#ed4956"
  end

  test "search results includes per-page selector with options 25 50 100" do
    get search_results_path

    assert_select "select[data-per-page-select]"
    assert_select "select[data-per-page-select] option[value='25']"
    assert_select "select[data-per-page-select] option[value='50']"
    assert_select "select[data-per-page-select] option[value='100']"
    assert_select "select[data-per-page-select] option[value='25'][selected]"
  end

  test "search results per-page selector respects valid per_page param" do
    get search_results_path(per_page: "50")

    assert_select "select[data-per-page-select] option[value='50'][selected]"
    assert_select "select[data-per-page-select] option[value='25']:not([selected])"
  end

  test "search results per-page selector defaults to 25 for invalid per_page param" do
    get search_results_path(per_page: "999")

    assert_select "select[data-per-page-select] option[value='25'][selected]"
  end

  test "search results per-page selector defaults to 25 for non-numeric per_page param" do
    get search_results_path(per_page: "invalid")

    assert_select "select[data-per-page-select] option[value='25'][selected]"
  end

  test "saved page includes pagination elements" do
    sign_in_with_firebase_email("student@u.northwestern.edu")

    get saved_path

    assert_select "[data-saved-grid]"
    assert_select "[data-saved-pagination]"
    assert_select "[data-saved-toolbar]"
    assert_select "[data-saved-per-page]"
    assert_select "[data-saved-per-page] option[value='25']"
    assert_select "[data-saved-per-page] option[value='50']"
    assert_select "[data-saved-per-page] option[value='100']"
  end

  test "search results retain date inputs and filter controls" do
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
    assert_includes response.body, "const validateDateRange = () =>"
    assert_includes response.body, "moveOutDate <= moveInDate"
    assert_select "button[data-filter-submit]"
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

  test "search results rejects matching move in and move out dates" do
    get search_results_path("move-in": "06/12/2026", "move-out": "06/12/2026")

    assert_select "[data-filter-error]", text: "Move-out date must be after move-in date."
    assert_select "[data-filter-error][hidden]", count: 0
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
    listing_owner("filter-missing-gym").sublet_listings.create!(
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
    listing_owner("filter-too-expensive").sublet_listings.create!(
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

  test "search results page includes pdf export link preserving filters" do
    get search_results_path(
      "move-in": "06/12/2026",
      "move-out": "09/11/2026",
      max_price: "1200",
      amenities: [ "Laundry" ],
      sort: "price_desc"
    )

    assert_select "a.export-pdf-link[href*='format=pdf']", text: "Export PDF"
    assert_select "a.export-pdf-link[href*='max_price=1200']"
    assert_select "a.export-pdf-link[href*='amenities%5B%5D=Laundry']"
    assert_select "a.export-pdf-link[href*='sort=price_desc']"
  end

  test "search results pdf route returns pdf content" do
    user = User.create!(
      name: "PDF Owner",
      email: "pdf.owner@u.northwestern.edu",
      active: true
    )
    listing_owner("pdf-missing-gym").sublet_listings.create!(
      valid_listing_attributes.merge(
        title: "PDF Route Match",
        available_from: Date.new(2026, 6, 1),
        available_until: Date.new(2026, 8, 31)
      )
    )
    sign_in_with_firebase_email("pdf.viewer@u.northwestern.edu")

    get search_results_path(format: :pdf, "move-in": "06/12/2026", "move-out": "08/01/2026")

    assert_response :success
    assert_equal "application/pdf", response.media_type
    assert response.body.start_with?("%PDF")
  end

  test "search results pdf export respects filtered and available listings" do
    user = User.create!(
      name: "PDF Filter Owner",
      email: "pdf.filter.owner@u.northwestern.edu",
      active: true
    )
    matching_listing = user.sublet_listings.create!(
      valid_listing_attributes.merge(
        title: "PDF Filter Match",
        price: 950,
        amenities: [ "Laundry", "Gym" ],
        available_from: Date.new(2026, 6, 1),
        available_until: Date.new(2026, 8, 31)
      )
    )
    listing_owner("pdf-outside-dates").sublet_listings.create!(
      valid_listing_attributes.merge(
        title: "PDF Missing Gym",
        price: 950,
        amenities: [ "Laundry" ],
        available_from: Date.new(2026, 6, 1),
        available_until: Date.new(2026, 8, 31)
      )
    )
    listing_owner("natural-too-expensive").sublet_listings.create!(
      valid_listing_attributes.merge(
        title: "PDF Outside Requested Dates",
        price: 950,
        amenities: [ "Laundry", "Gym" ],
        available_from: Date.new(2026, 9, 1),
        available_until: Date.new(2026, 12, 31)
      )
    )

    captured_listings = nil
    fake_pdf = Class.new do
      def render
        "%PDF-1.4\n"
      end
    end

    original_new = SearchResultsPdf.method(:new)
    SearchResultsPdf.define_singleton_method(:new) do |listings:, **|
      captured_listings = listings
      fake_pdf.new
    end
    sign_in_with_firebase_email("pdf.filter.viewer@u.northwestern.edu")

    begin
      get search_results_path(
        format: :pdf,
        "move-in": "06/12/2026",
        "move-out": "08/01/2026",
        amenities: [ "Laundry", "Gym" ],
        max_price: "1200"
      )
    ensure
      SearchResultsPdf.define_singleton_method(:new) { |*args, **kwargs| original_new.call(*args, **kwargs) }
    end

    assert_response :success
    assert_equal [ matching_listing.id ], captured_listings.map(&:id)
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
    listing_owner("search-ends-early").sublet_listings.create!(
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
    listing_owner("search-ends-early").sublet_listings.create!(
      valid_listing_attributes.merge(
        title: "Ends Too Early",
        available_from: Date.new(2026, 5, 24),
        available_until: Date.new(2026, 8, 15)
      )
    )
    listing_owner("search-starts-late").sublet_listings.create!(
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

  test "search results map renders google map payload for geocoded listings" do
    previous_google_maps_api_key = ENV["GOOGLE_MAPS_API_KEY"]
    ENV["GOOGLE_MAPS_API_KEY"] = "test-google-maps-key"
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
    single_listing.update_columns(latitude: 42.0583, longitude: -87.6831, geocoding_status: "geocoded", geocoded_at: Time.current)
    grouped_listing = listing_owner("map-group-a").sublet_listings.create!(
      valid_listing_attributes.merge(
        title: "Apartment Option A",
        address: "1570 Oak Ave, Apt 1, Evanston, IL 60201",
        price: 1100,
        available_from: Date.new(2026, 5, 24),
        available_until: Date.new(2026, 10, 3)
      )
    )
    grouped_listing.update_columns(latitude: 42.0479, longitude: -87.6872, geocoding_status: "geocoded", geocoded_at: Time.current)
    second_grouped_listing = listing_owner("map-group-b").sublet_listings.create!(
      valid_listing_attributes.merge(
        title: "Apartment Option B",
        address: "1570 Oak Ave, Apt 2, Evanston, IL 60201",
        price: 1200,
        available_from: Date.new(2026, 5, 24),
        available_until: Date.new(2026, 10, 3)
      )
    )
    second_grouped_listing.update_columns(latitude: 42.0479, longitude: -87.6872, geocoding_status: "geocoded", geocoded_at: Time.current)

    get search_results_path("move-in": "06/12/2026", "move-out": "09/11/2026")

    assert_select "[data-google-map-stage][data-google-maps-key-present='true']"
    assert_select "[data-google-map-canvas]"
    assert_select "[data-google-map-listings]", text: /Single Address Listing/
    assert_select "article.listing-card[data-listing-card][data-listing-id='#{single_listing.id}']"
    assert_includes response.body, "AdvancedMarkerElement"
    assert_includes response.body, "fitBounds"
    assert_includes response.body, "price-marker"
    assert_includes response.body, sublet_listing_path(grouped_listing)
  ensure
    ENV["GOOGLE_MAPS_API_KEY"] = previous_google_maps_api_key
  end

  test "search results backfills map coordinates when none are stored yet" do
    previous_google_maps_api_key = ENV["GOOGLE_MAPS_API_KEY"]
    previous_google_maps_geocoding_api_key = ENV["GOOGLE_MAPS_GEOCODING_API_KEY"]
    ENV["GOOGLE_MAPS_API_KEY"] = nil
    ENV["GOOGLE_MAPS_GEOCODING_API_KEY"] = nil

    user = User.create!(
      name: "Backfill Owner",
      email: "backfill.owner@u.northwestern.edu",
      active: true
    )
    listing = user.sublet_listings.create!(
      valid_listing_attributes.merge(
        title: "Backfill Match",
        address: "820 Noyes St, Evanston, IL 60201",
        price: 875,
        available_from: Date.new(2026, 5, 24),
        available_until: Date.new(2026, 10, 3)
      )
    )

    assert_nil listing.latitude
    assert_nil listing.longitude

    ENV["GOOGLE_MAPS_API_KEY"] = "test-google-maps-key"

    geocoding_client = Class.new do
      attr_reader :addresses

      def initialize
        @addresses = []
      end

      def geocode(address)
        @addresses << address
        GoogleGeocodingClient::Result.new(
          success?: true,
          latitude: BigDecimal("42.058300"),
          longitude: BigDecimal("-87.683100"),
          status: "geocoded"
        )
      end
    end.new

    original_new = GoogleGeocodingClient.method(:new)
    GoogleGeocodingClient.define_singleton_method(:new) { geocoding_client }

    get search_results_path("move-in": "06/12/2026", "move-out": "09/11/2026")

    assert_equal [ "820 Noyes St, Evanston, IL 60201" ], geocoding_client.addresses
    assert_in_delta 42.0583, listing.reload.latitude.to_f, 0.000001
    assert_in_delta(-87.6831, listing.reload.longitude.to_f, 0.000001)
    assert_select "[data-google-map-listings]", text: /Backfill Match/
    assert_select "[data-google-map-stage][data-google-maps-key-present='true']"
  ensure
    GoogleGeocodingClient.define_singleton_method(:new) { |*args, **kwargs| original_new.call(*args, **kwargs) } if defined?(original_new)
    ENV["GOOGLE_MAPS_API_KEY"] = previous_google_maps_api_key
    ENV["GOOGLE_MAPS_GEOCODING_API_KEY"] = previous_google_maps_geocoding_api_key
  end

  test "search results map shows setup message without google maps key" do
    previous_google_maps_api_key = ENV["GOOGLE_MAPS_API_KEY"]
    ENV["GOOGLE_MAPS_API_KEY"] = nil

    get search_results_path

    assert_select "[data-google-map-stage][data-google-maps-key-present='false']"
    assert_select "[data-google-map-empty]", text: /GOOGLE_MAPS_API_KEY/
  ensure
    ENV["GOOGLE_MAPS_API_KEY"] = previous_google_maps_api_key
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
    sign_in_with_firebase_email("detail.viewer@u.northwestern.edu")

    get sublet_listing_path(listing)

    assert_response :success
    assert_includes response.body, "May 24, 2026"
    assert_includes response.body, "October 3, 2026"
    assert_includes response.body, "Detail Date Match"
    assert_select "a[href='#{search_results_path}']", text: /Back to search results/
    assert_select "a[href='#{user_profile_path(user)}']", text: /Detail Owner/
    assert_select "a[href='#{user_profile_path(user)}'] img.host-avatar[alt='Detail Owner profile photo'][src='https://example.com/detail-owner.jpg']"
    assert_select ".listing-action-group[data-compare-listing]"
    assert_select "button[data-compare-trigger]", text: "Compare listing"
    assert_select "[data-compare-tray]"
    assert_select "[data-compare-modal]"
    assert_not_includes response.body, user.email
    assert_not_includes response.body, "mailto:#{user.email}"
    assert_not_includes response.body, "+1 (123) 456-7890"
    assert_not_includes response.body, "tel:+11234567890"
    assert_includes response.body, "Hidden by profile setting"
    assert_select "form.question-form[data-profanity-check]"
    assert_select "textarea[name='listing_question[body]'][data-profanity-field]"
    assert_select "form[data-profanity-check] textarea[name='listing_report[description]'][data-profanity-field]"

    user.update!(show_email_to_students: true)
    get sublet_listing_path(listing)

    assert_response :success
    assert_includes response.body, user.email
    assert_includes response.body, "mailto:#{user.email}"
  end

  test "listing page photo carousel handles fallback single and multiple photos" do
    no_photo_owner = User.create!(name: "No Photo Owner", email: "no.photo.owner@u.northwestern.edu", active: true)
    one_photo_owner = User.create!(name: "One Photo Owner", email: "one.photo.owner@u.northwestern.edu", active: true)
    multiple_photo_owner = User.create!(name: "Multiple Photo Owner", email: "multiple.photo.owner@u.northwestern.edu", active: true)
    photo_listing_attributes = valid_listing_attributes.merge(
      available_from: Date.new(2026, 6, 12),
      available_until: Date.new(2026, 9, 11)
    )
    listing_without_photos = no_photo_owner.sublet_listings.create!(
      photo_listing_attributes.merge(title: "No Photos Listing")
    )
    listing_with_one_photo = one_photo_owner.sublet_listings.create!(
      photo_listing_attributes.merge(
        title: "One Photo Listing",
        address: "900 Noyes St, Evanston, IL 60201"
      )
    )
    listing_with_one_photo.photos.attach(uploaded_test_file("single-photo.jpg", "image/jpeg", "single photo"))
    listing_with_multiple_photos = multiple_photo_owner.sublet_listings.create!(
      photo_listing_attributes.merge(
        title: "Multiple Photos Listing",
        address: "901 Noyes St, Evanston, IL 60201"
      )
    )
    listing_with_multiple_photos.photos.attach([
      uploaded_test_file("photo-one.jpg", "image/jpeg", "photo one"),
      uploaded_test_file("photo-two.jpg", "image/jpeg", "photo two"),
      uploaded_test_file("photo-three.jpg", "image/jpeg", "photo three")
    ])

    sign_in_with_firebase_email("photo.viewer@u.northwestern.edu")

    get sublet_listing_path(listing_without_photos)

    assert_response :success
    assert_select "section.photo-carousel[data-photo-carousel]"
    assert_select ".gallery-grid", count: 0
    assert_select "[data-photo-carousel-source]", count: 1
    assert_select "[data-photo-carousel-total]", text: "1"
    assert_select "[data-photo-carousel-previous]", count: 0
    assert_select "[data-photo-carousel-next]", count: 0

    get sublet_listing_path(listing_with_one_photo)

    assert_response :success
    assert_select "[data-photo-carousel-source]", count: 1
    assert_select "[data-photo-carousel-total]", text: "1"
    assert_select "[data-photo-carousel-previous]", count: 0
    assert_select "[data-photo-carousel-next]", count: 0

    get sublet_listing_path(listing_with_multiple_photos)

    assert_response :success
    assert_select "[data-photo-carousel-source]", count: 3
    assert_select "[data-photo-carousel-current]", text: "1"
    assert_select "[data-photo-carousel-total]", text: "3"
    assert_select "button[data-photo-carousel-previous][aria-label='Previous photo']"
    assert_select "button[data-photo-carousel-next][aria-label='Next photo']"
    assert_includes response.body, "const movePhoto = (direction) =>"
  end

  test "listing detail page shows delete controls only to the owner" do
    owner = User.create!(name: "Listing Manager", email: "listing.manager@u.northwestern.edu", active: true)
    listing = owner.sublet_listings.create!(
      valid_listing_attributes.merge(
        title: "Owner Managed Listing",
        available_from: Date.new(2026, 5, 24),
        available_until: Date.new(2026, 10, 3)
      )
    )

    sign_in_with_firebase_email(owner.email)
    get sublet_listing_path(listing)

    assert_response :success
    assert_select ".owner-listing-actions"
    assert_select "a[href='#{profile_path}']", text: "Edit listing"
    assert_select "form[action='#{sublet_listing_path(listing)}'][method='post'] button.owner-delete-button", text: "Delete listing"
    assert_select "form[action='#{sublet_listing_path(listing)}'][method='post'] button.owner-delete-button[data-turbo-confirm='Are you sure you want to delete this listing?']"
    assert_select "form[action='#{sublet_listing_path(listing)}'][data-turbo-confirm='Are you sure you want to delete this listing?']"
    assert_select "form[action='#{sublet_listing_path(listing)}'][onsubmit=\"return !!window.Turbo || confirm('Are you sure you want to delete this listing?');\"]"
    assert_select "form[action='#{sublet_listing_path(listing)}'] input[name='_method'][value='delete']", visible: false
    assert_includes response.body, "Are you sure you want to delete this listing?"
    assert_select "button[data-compare-trigger]", count: 0
    assert_select "button[data-report-modal-trigger]", count: 0

    delete session_path
    sign_in_with_firebase_email("listing.manager.viewer@u.northwestern.edu")
    get sublet_listing_path(listing)

    assert_response :success
    assert_select ".owner-listing-actions", count: 0
    assert_select "button[data-compare-trigger]", text: "Compare listing"
    assert_select "button[data-report-modal-trigger]", text: "Report listing"
  end

  test "listing fallback page has a clickable compare button" do
    sign_in_with_firebase_email("fallback.viewer@u.northwestern.edu")

    get listing_path

    assert_response :success
    assert_select ".listing-action-group[data-compare-listing]"
    assert_select "button[data-compare-trigger]", text: "Compare listing"
    assert_select "button[data-compare-trigger][disabled]", count: 0
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
    sign_in_with_firebase_email("question.viewer@u.northwestern.edu")

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

  test "turbo stream question create updates the questions section" do
    host = User.create!(name: "Turbo Question Host", email: "turbo.ask.host@u.northwestern.edu", active: true)
    listing = host.sublet_listings.create!(
      valid_listing_attributes.merge(
        title: "Turbo Askable Listing",
        available_from: Date.new(2026, 5, 24),
        available_until: Date.new(2026, 10, 3)
      )
    )
    sign_in_with_firebase_email("turbo.ask.renter@u.northwestern.edu")

    assert_difference("ListingQuestion.count", 1) do
      post sublet_listing_questions_path(listing),
           params: { listing_question: { body: "Can I tour this weekend?" } },
           as: :turbo_stream
    end

    assert_response :success
    assert_equal Mime[:turbo_stream].to_s, response.media_type
    assert_includes response.body, 'turbo-stream action="replace" target="listing_questions"'
    assert_includes response.body, "Question posted."
    assert_includes response.body, "Can I tour this weekend?"
  end

  test "listing question blocks profanity and shows an error" do
    host = User.create!(name: "Question Host", email: "blocked.question.host@u.northwestern.edu", active: true)
    listing = host.sublet_listings.create!(
      valid_listing_attributes.merge(
        title: "Blocked Question Listing",
        available_from: Date.new(2026, 5, 24),
        available_until: Date.new(2026, 10, 3)
      )
    )
    sign_in_with_firebase_email("blocked.question.renter@u.northwestern.edu")

    assert_no_difference("ListingQuestion.count") do
      post sublet_listing_questions_path(listing), params: { listing_question: { body: "Is this shit available?" } }
    end

    assert_redirected_to sublet_listing_path(listing, anchor: "questions")
    follow_redirect!
    assert_includes response.body, ProfanityFilter::ERROR_MESSAGE
  end

  test "turbo stream question errors render feedback without redirecting" do
    host = User.create!(name: "Turbo Error Host", email: "turbo.error.host@u.northwestern.edu", active: true)
    listing = host.sublet_listings.create!(
      valid_listing_attributes.merge(
        title: "Turbo Error Listing",
        available_from: Date.new(2026, 5, 24),
        available_until: Date.new(2026, 10, 3)
      )
    )
    sign_in_with_firebase_email("turbo.error.renter@u.northwestern.edu")

    assert_no_difference("ListingQuestion.count") do
      post sublet_listing_questions_path(listing),
           params: { listing_question: { body: "Is this shit available?" } },
           as: :turbo_stream
    end

    assert_response :unprocessable_entity
    assert_equal Mime[:turbo_stream].to_s, response.media_type
    assert_includes response.body, 'turbo-stream action="replace" target="listing_questions"'
    assert_includes response.body, ProfanityFilter::ERROR_MESSAGE
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

  test "turbo stream question answer updates the questions section" do
    host = User.create!(name: "Turbo Answer Host", email: "turbo.answer.host@u.northwestern.edu", active: true)
    renter = User.create!(name: "Turbo Answer Renter", email: "turbo.answer.renter@u.northwestern.edu", active: true)
    listing = host.sublet_listings.create!(
      valid_listing_attributes.merge(
        title: "Turbo Answer Listing",
        available_from: Date.new(2026, 5, 24),
        available_until: Date.new(2026, 10, 3)
      )
    )
    question = listing.listing_questions.create!(user: renter, body: "Is laundry included?")

    sign_in_with_firebase_email(host.email)
    patch listing_question_path(question),
          params: { listing_question: { answer: "Yes, in building." } },
          as: :turbo_stream

    assert_response :success
    assert_equal Mime[:turbo_stream].to_s, response.media_type
    assert_includes response.body, "Answer posted."
    assert_includes response.body, "Yes, in building."
    assert_equal "Yes, in building.", question.reload.answer
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

  test "turbo stream question delete refreshes the questions section" do
    host = User.create!(name: "Turbo Delete Host", email: "turbo.delete.host@u.northwestern.edu", active: true)
    renter = User.create!(name: "Turbo Delete Renter", email: "turbo.delete.renter@u.northwestern.edu", active: true)
    listing = host.sublet_listings.create!(
      valid_listing_attributes.merge(
        title: "Turbo Delete Listing",
        available_from: Date.new(2026, 5, 24),
        available_until: Date.new(2026, 10, 3)
      )
    )
    question = listing.listing_questions.create!(user: renter, body: "Will this disappear?")

    sign_in_with_firebase_email(renter.email)

    assert_difference("ListingQuestion.count", -1) do
      delete listing_question_path(question), as: :turbo_stream
    end

    assert_response :success
    assert_equal Mime[:turbo_stream].to_s, response.media_type
    assert_includes response.body, "Question deleted."
    assert_includes response.body, "No questions yet."
    assert_not_includes response.body, "Will this disappear?"
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

    assert_redirected_to login_path
    assert_not_includes response.body, user.email

    sign_in_with_firebase_email("profile.viewer@u.northwestern.edu")
    get user_profile_path(user)

    assert_response :success
    assert_select "h1", text: "Profile Owner"
    assert_select "img.profile-avatar[alt='Profile Owner profile avatar'][src='https://example.com/profile-owner.jpg']"
    assert_includes response.body, "Verified Northwestern student"
    assert_select "a[href='#{sublet_listing_path(listing)}']", text: /Owner Profile Link/
    assert_select "a[href='#{sublet_listing_path(listing)}'] img.listing-avatar[alt='Profile Owner listing avatar'][src='https://example.com/profile-owner.jpg']"
  end

  test "signed out users cannot view another user account page" do
    get another_user_account_path

    assert_redirected_to login_path
  end

  test "post sublet page uses the submit endpoint" do
    get post_sublet_path

    assert_select "form[action='#{submit_sublet_path}'][method='post']"
    assert_select ".required-indicator", text: "*", count: 7
    assert_select "#address-section-title .required-indicator", text: "*"
    assert_select "#rent-section-title .required-indicator", text: "*"
    assert_select "#description-section-title .required-indicator", text: "*"
    assert_select "span.field-label", text: /Start Date\s*\*/
    assert_select "span.field-label", text: /End Date\s*\*/
    assert_select "span.field-label", text: /Bedrooms\s*\*/
    assert_select "span.field-label", text: /Bathrooms\s*\*/
    assert_select "h2#amenities-section-title .required-indicator", count: 0
    assert_select "h2#preferences-section-title .required-indicator", count: 0
    assert_select "h2#photos-section-title .required-indicator", count: 0
    assert_select "h2#phone-section-title .required-indicator", count: 0
    assert_select "form[data-profanity-check]"
    assert_select "textarea[name='description'][data-profanity-field]"
    assert_select "select[name='bedrooms'] option[value='0']", text: "Studio"
    assert_select "select[name='bedrooms'] option[value='20']", text: "20 bedrooms"
    assert_select "select[name='bathrooms'] option[value='0']", text: "0 bathrooms"
    assert_select "select[name='bathrooms'] option[value='20']", text: "20 bathrooms"
    assert_select "input[name='school-email']", count: 0
    assert_select "input[type='file'][name='photos[]'][accept='image/png,image/jpeg,image/webp'][multiple]"
    assert_includes response.body, "Upload up to 5 photos. PNG, JPG, or WebP only. 5 MB max per photo."
    assert_includes response.body, "data-profanity-words"
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
    if response.media_type == "application/json" && response.parsed_body["requires_terms_acceptance"]
      post onboarding_accept_terms_path, params: { terms_accepted: "1" }
    end
  ensure
    FirebaseTokenVerifier.define_singleton_method(:new) { |*args, **kwargs| original_new.call(*args, **kwargs) }
  end

  def uploaded_test_file(filename, content_type, content)
    file = Tempfile.new([ File.basename(filename, ".*"), File.extname(filename) ], binmode: true)
    file.write(content)
    file.rewind

    Rack::Test::UploadedFile.new(file.path, content_type, original_filename: filename)
  end

  def listing_owner(slug)
    User.create!(
      name: "Listing Owner #{slug.titleize}",
      email: "listing.owner.#{slug}@u.northwestern.edu",
      active: true
    )
  end
end
