require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
  test "central_time_display formats timestamps in America Chicago with CT label" do
    assert_equal "Jun 7, 2026 8:18 PM CT", central_time_display(Time.utc(2026, 6, 8, 1, 18, 0))
  end

  test "central_time_display handles nil safely" do
    assert_equal "", central_time_display(nil)
  end

  test "user_avatar_url uses initials for demo placeholder photos" do
    user = User.new(
      name: "Melinda Tester",
      email: "melinda@u.northwestern.edu",
      profile_photo_url: "https://randomuser.me/api/portraits/men/73.jpg"
    )

    avatar_url = user_avatar_url(user, size: 100)

    assert_includes avatar_url, "ui-avatars.com/api"
    assert_includes avatar_url, "name=MT"
    assert_includes avatar_url, "size=100"
  end

  test "user_avatar_url preserves real profile photo urls" do
    user = User.new(
      name: "Real Photo",
      email: "real.photo@u.northwestern.edu",
      profile_photo_url: "https://example.com/real-photo.jpg"
    )

    assert_equal "https://example.com/real-photo.jpg", user_avatar_url(user, size: 100)
  end

  test "listing map places hinman avenue addresses on land" do
    listing = SubletListing.new(address: "1401 Hinman Ave, Evanston, IL 60201")

    group = listing_map_groups([ listing ]).first

    assert_operator group[:x], :<, ApplicationHelper::EVANSTON_MAP_WATER_START_X
    assert_in_delta 70, group[:x], 0.1
  end

  test "listing map uses address number for north south street placement" do
    south_listing = SubletListing.new(address: "700 Hinman Ave, Evanston, IL 60201")
    north_listing = SubletListing.new(address: "2200 Hinman Ave, Evanston, IL 60201")

    south_group, north_group = listing_map_groups([ south_listing, north_listing ])

    assert_operator south_group[:y], :>, north_group[:y]
    assert_equal south_group[:x], north_group[:x]
  end

  test "google map listing payload includes only geocoded listings" do
    geocoded_listing = SubletListing.new(
      id: 42,
      title: "Mapped Listing",
      address: "820 Noyes St, Evanston, IL 60201",
      price: 1250,
      bedrooms: 1,
      bathrooms: 1,
      available_from: Date.new(2026, 6, 1),
      available_until: Date.new(2026, 8, 31),
      latitude: 42.0583,
      longitude: -87.6831
    )
    unmapped_listing = SubletListing.new(
      id: 43,
      title: "Unmapped Listing",
      address: "910 Noyes St, Evanston, IL 60201",
      price: 950,
      bedrooms: 1,
      bathrooms: 1
    )

    payload = google_map_listing_payload([ geocoded_listing, unmapped_listing ])

    assert_equal 1, payload.length
    assert_equal "42", payload.first[:id]
    assert_equal "$1.3k", payload.first[:priceLabel]
    assert_equal 42.0583, payload.first[:latitude]
    assert_equal -87.6831, payload.first[:longitude]
  end

  test "amenity icon renders accessible decorative svg" do
    icon = amenity_icon("Laundry")

    assert_includes icon, 'class="amenity-icon"'
    assert_includes icon, 'aria-hidden="true"'
    assert_includes icon, 'focusable="false"'
    assert_includes icon, 'stroke="currentColor"'
  end

  test "footer nav icons use consistent current color glyphs" do
    footer_outline_icons = %i[about_us privacy_policy community_guidelines disclaimer]

    footer_outline_icons.each do |icon_name|
      icon = ApplicationHelper::NAV_ITEM_ICONS.fetch(icon_name)

      assert_includes icon, 'class="nav-item-icon footer-nav-icon"'
      assert_includes icon, 'viewBox="0 0 16 16"'
      assert_includes icon, 'aria-hidden="true"'
      assert_includes icon, 'focusable="false"'
      assert_includes icon, 'fill="none"'
      assert_includes icon, 'stroke="currentColor"'
      assert_includes icon, 'stroke-width="1.45"'
      refute_includes icon, 'fill="currentColor"'
      refute_includes icon, 'fill="white"'
    end

    github_icon = ApplicationHelper::NAV_ITEM_ICONS.fetch(:github)

    assert_includes github_icon, 'class="nav-item-icon footer-nav-icon footer-nav-icon--github"'
    assert_includes github_icon, 'transform="translate(1.25 1.25) scale(0.84375)"'
  end

  test "amenity icon has a mapping for every allowed amenity" do
    missing_amenities = SubletListing::AMENITY_OPTIONS - ApplicationHelper::AMENITY_ICON_PATHS.keys

    assert_empty missing_amenities
  end

  test "listing image helper uses one intentional default for listings without uploaded photos" do
    first_listing = SubletListing.new(id: 1, title: "First Listing")
    second_listing = SubletListing.new(id: 2, title: "Second Listing")
    expected_default = asset_path(ApplicationHelper::DEFAULT_LISTING_IMAGE_ASSET)

    assert_equal expected_default, apartment_listing_image_path(first_listing)
    assert_equal expected_default, apartment_listing_image_path(second_listing)
    assert_equal Array.new(4, expected_default), apartment_gallery_image_paths(first_listing)
  end
end
