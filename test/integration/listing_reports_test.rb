require "test_helper"

class ListingReportsTest < ActionDispatch::IntegrationTest
  include ActiveSupport::Testing::TimeHelpers

  setup do
    travel_to Date.new(2026, 5, 1)
    @host = User.create!(name: "Host User", email: "host.user@u.northwestern.edu", active: true)
    @reporter = User.create!(
      name: "Reporter User",
      email: "reporter.user@u.northwestern.edu",
      password: "password123",
      password_confirmation: "password123",
      confirmed_at: Time.current,
      active: true
    )
    @listing = @host.sublet_listings.create!(valid_listing_params)
  end

  teardown do
    travel_back
  end

  test "requires login to report a listing" do
    assert_no_difference("ListingReport.count") do
      post sublet_listing_reports_path(@listing), params: {
        listing_report: { description: "This content violates policy." }
      }
    end

    assert_redirected_to login_path
  end

  test "signed in user can report a listing" do
    sign_in(@reporter)

    assert_difference("ListingReport.count", 1) do
      post sublet_listing_reports_path(@listing), params: {
        listing_report: { description: "The listing asks for payment outside the platform." }
      }
    end

    report = ListingReport.order(:created_at).last
    assert_equal @listing, report.sublet_listing
    assert_equal @reporter, report.user
    assert_equal "The listing asks for payment outside the platform.", report.description
    assert_redirected_to sublet_listing_path(@listing)
  end

  test "listing page shows report modal for signed in users" do
    sign_in(@reporter)

    get sublet_listing_path(@listing)

    assert_response :success
    assert_select "[data-report-modal-trigger]", text: /Report listing/
    assert_select "#report-modal"
    assert_select "textarea[name='listing_report[description]']"
  end

  private

  def sign_in(user)
    post session_path, params: { email: user.email, password: "password123" }
    assert_redirected_to profile_path
  end

  def valid_listing_params
    {
      title: "Sunny Room Near Campus",
      description: "Clean furnished room within walking distance of campus.",
      price: 1200,
      address: "820 Noyes St, Evanston, IL 60201",
      bedrooms: 1,
      bathrooms: 1,
      furnished: true,
      pets_allowed: false,
      utilities_included: true,
      available_from: Date.current + 1.day,
      available_until: Date.current + 60.days
    }
  end
end
