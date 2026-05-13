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
end
