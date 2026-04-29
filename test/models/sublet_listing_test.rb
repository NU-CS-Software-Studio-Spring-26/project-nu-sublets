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
