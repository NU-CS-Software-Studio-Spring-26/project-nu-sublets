require "test_helper"

class SubletListingTest < ActiveSupport::TestCase
  def setup
    @uploaded_files = []
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

  test "valid listing with acceptable image uploads succeeds" do
    listing = @user.sublet_listings.new(valid_listing_params)
    listing.photos.attach([
      uploaded_file("listing-photo-one.png", "image/png", png_bytes),
      uploaded_file("listing-photo-two.webp", "image/webp", "RIFF----WEBPVP8 ")
    ])

    assert listing.valid?
    assert listing.save
    assert_equal 2, listing.photos.count
  end

  test "uploading more than five images fails with a friendly error" do
    listing = @user.sublet_listings.new(valid_listing_params)
    listing.photos.attach(
      6.times.map { |index| uploaded_file("listing-photo-#{index}.png", "image/png", png_bytes) }
    )

    assert_not listing.valid?
    assert_includes listing.errors[:base], "You can upload up to 5 photos per listing."
  end

  test "uploading an image larger than five megabytes fails with a friendly error" do
    listing = @user.sublet_listings.new(valid_listing_params)
    listing.photos.attach(uploaded_file("large-listing-photo.png", "image/png", large_png_bytes))

    assert_not listing.valid?
    assert_includes listing.errors[:base], "Each photo must be 5 MB or smaller."
  end

  test "uploading a non image file fails with a friendly error" do
    listing = @user.sublet_listings.new(valid_listing_params)
    listing.photos.attach(uploaded_file("lease.pdf", "application/pdf", "%PDF-1.4 fake pdf"))

    assert_not listing.valid?
    assert_includes listing.errors[:base], "Photos must be PNG, JPG, or WebP files."
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
    assert_equal [ covers_full_stay ], results.to_a
  end

  test "search_listings filters by price amenities and preferences" do
    matching_listing = @user.sublet_listings.create!(
      valid_listing_params.merge(
        title: "Filtered Match",
        price: 950,
        amenities: [ "Laundry", "Gym", "Utilities included" ],
        preferences: [ "Graduate student", "Quiet" ],
        utilities_included: true
      )
    )
    @user.sublet_listings.create!(
      valid_listing_params.merge(
        title: "Wrong Amenities",
        price: 900,
        amenities: [ "Parking" ],
        preferences: [ "Social" ],
        utilities_included: false
      )
    )
    @user.sublet_listings.create!(
      valid_listing_params.merge(
        title: "Too Expensive",
        price: 1800,
        amenities: [ "Laundry", "Gym", "Utilities included" ],
        preferences: [ "Graduate student", "Quiet" ],
        utilities_included: true
      )
    )

    results = SubletListing.search_listings(
      min_price: "800",
      max_price: "1200",
      amenities: [ "Laundry", "Utilities included" ],
      preferences: [ "Graduate student" ]
    )

    assert_equal [ matching_listing ], results.to_a
  end

  test "search_listings matches preference labels exactly" do
    female_listing = @user.sublet_listings.create!(
      valid_listing_params.merge(
        title: "Female Roommate Match",
        preferences: [ "Female", "Clean" ]
      )
    )
    male_listing = @user.sublet_listings.create!(
      valid_listing_params.merge(
        title: "Male Roommate Match",
        preferences: [ "Male", "Clean" ]
      )
    )

    female_results = SubletListing.search_listings(preferences: [ "Female" ])
    male_results = SubletListing.search_listings(preferences: [ "Male" ])

    assert_includes female_results, female_listing
    assert_not_includes female_results, male_listing
    assert_includes male_results, male_listing
    assert_not_includes male_results, female_listing
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

  def uploaded_file(filename, content_type, content)
    file = Tempfile.new([ File.basename(filename, ".*"), File.extname(filename) ], binmode: true)
    file.write(content)
    file.rewind
    @uploaded_files << file

    Rack::Test::UploadedFile.new(file.path, content_type, original_filename: filename)
  end

  def png_bytes
    "\x89PNG\r\n\x1A\n".b
  end

  def large_png_bytes
    png_bytes + ("0" * (SubletListing::MAX_PHOTO_SIZE + 1))
  end
end
