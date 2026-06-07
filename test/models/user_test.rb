require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "create_user creates a valid user" do
    result = User.create_user(
      name: "Test User",
      email: "test.user@u.northwestern.edu",
      first_name: "Test",
      last_name: "User",
      active: true
    )

    assert result[:success]
    assert_instance_of User, result[:user]
    assert_equal "User created successfully", result[:message]
  end

  test "update_profile updates attributes" do
    user = User.create!(
      name: "Original Name",
      email: "original@u.northwestern.edu",
      first_name: "Original",
      last_name: "Name",
      active: true
    )

    result = user.update_profile(name: "Updated Name")

    assert result[:success]
    assert_equal "Updated Name", user.reload.name
  end

  test "rejects profanity in profile text" do
    user = User.new(
      name: "Profile Student",
      email: "profile.profanity@u.northwestern.edu",
      bio: "This bio has shit language.",
      active: true
    )

    assert_not user.valid?
    assert_includes user.errors[:base], ProfanityFilter::ERROR_MESSAGE
  end

  test "rejects overly long profile text" do
    user = User.new(
      name: "N" * (User::MAX_NAME_LENGTH + 1),
      email: "long.profile@u.northwestern.edu",
      bio: "B" * (User::MAX_BIO_LENGTH + 1),
      active: true
    )

    assert_not user.valid?
    assert_includes user.errors[:name], "is too long (maximum is #{User::MAX_NAME_LENGTH} characters)"
    assert_includes user.errors[:bio], "is too long (maximum is #{User::MAX_BIO_LENGTH} characters)"
  end

  test "rejects oversized profile photos" do
    user = User.new(
      name: "Profile Photo",
      email: "profile.photo@u.northwestern.edu",
      active: true
    )
    user.profile_photo.attach(
      io: StringIO.new("x" * (User::MAX_PROFILE_PHOTO_SIZE + 1)),
      filename: "large-profile.png",
      content_type: "image/png"
    )

    assert_not user.valid?
    assert_includes user.errors[:profile_photo], "must be 5 MB or smaller"
  end

  test "soft_delete marks user inactive" do
    user = User.create!(
      name: "Soft Delete",
      email: "soft.delete@u.northwestern.edu",
      first_name: "Soft",
      last_name: "Delete",
      active: true
    )

    user.soft_delete

    assert_not user.reload.active
    assert_not_nil user.deleted_at
  end

  test "full_name combines first and last name" do
    user = User.new(first_name: "Jane", last_name: "Doe")

    assert_equal "Jane Doe", user.full_name
  end

  test "confirmed reflects confirmed_at presence" do
    assert User.new(confirmed_at: Time.current).confirmed?
    assert_not User.new.confirmed?
  end
end
