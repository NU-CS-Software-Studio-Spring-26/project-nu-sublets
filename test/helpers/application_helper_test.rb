require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
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
end
