require "test_helper"

class SubletListingTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(
      name: "Listing Owner",
      email: "listing.owner@u.northwestern.edu",
      first_name: "Listing",
      last_name: "Owner",
      active: true
    )
  end

  test "create_listing creates a valid listing" do
    result = SubletListing.create_listing(@user, valid_listing_params)

    assert result[:success]
    assert_instance_of SubletListing, result[:listing]
    assert_equal "Listing created successfully", result[:message]
  end

  test "update_listing updates attributes" do
    listing = @user.sublet_listings.create!(valid_listing_params)

    result = listing.update_listing(price: 1500)

    assert result[:success]
    assert_equal 1500, listing.reload.price.to_i
  end

  test "delete_listing removes the record" do
    listing = @user.sublet_listings.create!(valid_listing_params)

    assert_difference("SubletListing.count", -1) do
      listing.delete_listing
    end
  end

  test "invalid when available_until is before available_from" do
    listing = @user.sublet_listings.new(
      valid_listing_params.merge(
        available_from: Date.current + 10.days,
        available_until: Date.current + 5.days
      )
    )

    assert_not listing.valid?
    assert_includes listing.errors[:available_until], "must be after the available from date"
  end

  test "currently_available returns true for active date window" do
    listing = @user.sublet_listings.create!(
      valid_listing_params.merge(
        available_from: Date.current,
        available_until: Date.current + 30.days
      )
    )

    assert listing.currently_available?
  end

  test "short_address returns the first address segment" do
    listing = @user.sublet_listings.create!(valid_listing_params)

    assert_equal "820 Noyes St", listing.short_address
  end

  test "search_listings only returns listings covering the full requested stay" do
    covers_full_stay = @user.sublet_listings.create!(
      valid_listing_params.merge(
        title: "Full Summer and Fall Stay",
        available_from: Date.new(2026, 6, 1),
        available_until: Date.new(2026, 9, 30)
      )
    )
    @user.sublet_listings.create!(
      valid_listing_params.merge(
        title: "Ends Before Requested Move Out",
        available_from: Date.new(2026, 6, 1),
        available_until: Date.new(2026, 8, 15)
      )
    )
    @user.sublet_listings.create!(
      valid_listing_params.merge(
        title: "Starts After Requested Move In",
        available_from: Date.new(2026, 7, 1),
        available_until: Date.new(2026, 9, 30)
      )
    )

    results = SubletListing.search_listings(
      move_in: Date.new(2026, 6, 12),
      move_out: Date.new(2026, 9, 11)
    )

    assert_includes results, covers_full_stay
    assert_equal [covers_full_stay], results.to_a
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
