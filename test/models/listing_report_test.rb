require "test_helper"

class ListingReportTest < ActiveSupport::TestCase
  include ActiveSupport::Testing::TimeHelpers

  setup do
    travel_to Date.new(2026, 5, 1)
    @host = User.create!(name: "Host User", email: "host.user@u.northwestern.edu", active: true)
    @reporter = User.create!(name: "Reporter User", email: "reporter.user@u.northwestern.edu", active: true)
    @listing = @host.sublet_listings.create!(valid_listing_params)
  end

  teardown do
    travel_back
  end

  test "valid with listing user and description" do
    report = @listing.listing_reports.new(user: @reporter, description: "This listing uses misleading photos.")

    assert report.valid?
  end

  test "rejects blank and too long description" do
    blank_report = @listing.listing_reports.new(user: @reporter, description: "   ")
    long_report = @listing.listing_reports.new(user: @reporter, description: "a" * 1_001)

    assert_not blank_report.valid?
    assert_includes blank_report.errors[:description], "can't be blank"
    assert_not long_report.valid?
    assert_includes long_report.errors[:description], "is too long (maximum is 1000 characters)"
  end

  test "normalizes description text" do
    report = @listing.listing_reports.create!(
      user: @reporter,
      description: "  Contains\u0000 unsafe\n payment request.  "
    )

    assert_equal "Contains unsafe payment request.", report.description
  end

  test "rejects profanity in report description" do
    report = @listing.listing_reports.new(user: @reporter, description: "This report says shit.")

    assert_not report.valid?
    assert_includes report.errors[:base], ProfanityFilter::ERROR_MESSAGE
  end

  test "destroyed when listing is destroyed" do
    @listing.listing_reports.create!(user: @reporter, description: "This should be reviewed.")

    assert_difference("ListingReport.count", -1) do
      @listing.destroy
    end
  end

  private

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
