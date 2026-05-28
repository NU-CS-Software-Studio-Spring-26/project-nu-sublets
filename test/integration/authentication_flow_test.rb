require "test_helper"

class AuthenticationFlowTest < ActionDispatch::IntegrationTest
  include ActiveSupport::Testing::TimeHelpers

  setup do
    travel_to Date.new(2026, 5, 1)
    Rails.application.env_config.delete("omniauth.auth")
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:google_oauth2] = nil
  end

  teardown do
    travel_back
    Rails.application.env_config.delete("omniauth.auth")
    OmniAuth.config.mock_auth[:google_oauth2] = nil
    OmniAuth.config.test_mode = false
  end

  test "local password signup is disabled even with a Northwestern email" do
    assert_no_difference("User.count") do
      post signup_path, params: {
        user: {
          name: "Local Student",
          email: "local.student@u.northwestern.edu",
          password: "password123",
          password_confirmation: "password123"
        }
      }
    end

    assert_redirected_to login_path
    follow_redirect!
    assert_includes response.body, "Use Google sign-in with your Northwestern account to create an account."
  end

  test "unconfirmed local login is blocked" do
    user = create_password_user(email: "unconfirmed.student@u.northwestern.edu", password: "password123", confirmed: false)

    post session_path, params: { email: user.email, password: "password123" }

    assert_response :unprocessable_entity
    assert_includes response.body, "Use Google sign-in with your Northwestern account to verify before logging in."
  end

  test "login page shows Google sign in without setup warning" do
    get login_path

    assert_response :success
    google_action = if ENV["GOOGLE_CLIENT_ID"].present? && ENV["GOOGLE_CLIENT_SECRET"].present?
                      "/auth/google_oauth2"
    else
                      google_oauth_path
    end

    assert_select "form[action='#{google_action}'] button", text: "Sign in with Google"
    assert_select "form[action='#{session_path}']", count: 0
    assert_no_match "Google sign-in is not configured yet", response.body
  end

  test "unconfigured Google OAuth route redirects back to login with a safe error" do
    post google_oauth_path

    assert_redirected_to login_path
    follow_redirect!
    assert_includes response.body, "Google sign-in is unavailable until OAuth credentials are configured."
  end

  test "local password signup is disabled with a non Northwestern email" do
    assert_no_difference("User.count") do
      post signup_path, params: {
        user: {
          name: "Outside Student",
          email: "outside@example.com",
          password: "password123",
          password_confirmation: "password123"
        }
      }
    end

    assert_redirected_to login_path
  end

  test "successful local login" do
    user = create_password_user(email: "login.student@u.northwestern.edu", password: "password123")

    post session_path, params: { email: user.email, password: "password123" }

    assert_redirected_to profile_path
    follow_redirect!
    assert_response :success
    assert_includes response.body, "login.student@u.northwestern.edu"
  end

  test "failed local login uses a generic error" do
    create_password_user(email: "generic.student@u.northwestern.edu", password: "password123")

    post session_path, params: { email: "missing@u.northwestern.edu", password: "wrong-password" }

    assert_response :unprocessable_entity
    assert_includes response.body, "Invalid email or password."
    assert_no_match "missing@u.northwestern.edu", response.body
  end

  test "logout clears the session" do
    user = create_password_user(email: "logout.student@u.northwestern.edu", password: "password123")
    post session_path, params: { email: user.email, password: "password123" }

    delete session_path

    assert_redirected_to root_path

    get profile_path
    assert_redirected_to login_path
  end

  test "successful Google OAuth login with a Northwestern email" do
    OmniAuth.config.mock_auth[:google_oauth2] = google_auth_hash(email: "google.student@u.northwestern.edu")

    assert_difference("User.count", 1) do
      post "/auth/google_oauth2"
      follow_redirect!
    end

    user = User.find_by!(email: "google.student@u.northwestern.edu")
    assert_equal "google_oauth2", user.provider
    assert_equal "google-123", user.uid
    assert user.confirmed?
    assert_redirected_to profile_path
  end

  test "rejects Google OAuth login with a non Northwestern email" do
    OmniAuth.config.mock_auth[:google_oauth2] = google_auth_hash(email: "google@example.com")

    assert_no_difference("User.count") do
      post "/auth/google_oauth2"
      follow_redirect!
    end

    assert_redirected_to login_path
    follow_redirect!
    assert_includes response.body, "Use your Northwestern Google account to log in."
  end

  test "Google OAuth does not duplicate existing users with the same email" do
    existing_user = create_password_user(email: "existing.google@u.northwestern.edu", password: "password123")
    OmniAuth.config.mock_auth[:google_oauth2] = google_auth_hash(email: existing_user.email, uid: "google-456")

    assert_no_difference("User.count") do
      post "/auth/google_oauth2"
      follow_redirect!
    end

    existing_user.reload
    assert_equal "google_oauth2", existing_user.provider
    assert_equal "google-456", existing_user.uid
    assert existing_user.confirmed?
    assert_redirected_to profile_path
  end

  test "protected pages require login" do
    get profile_path

    assert_redirected_to login_path
  end

  test "users cannot update listings they do not own" do
    owner = create_password_user(email: "owner@u.northwestern.edu")
    other_user = create_password_user(email: "other@u.northwestern.edu")
    listing = owner.sublet_listings.create!(valid_listing_attributes.merge(title: "Owner Listing"))
    post session_path, params: { email: other_user.email, password: "password123" }

    patch sublet_listing_path(listing), params: { sublet_listing: { title: "Changed by Other User" } }

    assert_redirected_to sublet_listing_path(listing)
    assert_equal "Owner Listing", listing.reload.title
  end

  test "users cannot delete listings they do not own" do
    owner = create_password_user(email: "delete.owner@u.northwestern.edu")
    other_user = create_password_user(email: "delete.other@u.northwestern.edu")
    listing = owner.sublet_listings.create!(valid_listing_attributes.merge(title: "Protected Listing"))
    post session_path, params: { email: other_user.email, password: "password123" }

    assert_no_difference("SubletListing.count") do
      delete sublet_listing_path(listing)
    end

    assert_redirected_to sublet_listing_path(listing)
  end

  private

  def create_password_user(email:, password: "password123", confirmed: true)
    User.create!(
      name: "Test Student",
      email: email,
      password: password,
      password_confirmation: password,
      confirmed_at: (Time.current if confirmed),
      active: true
    )
  end

  def google_auth_hash(email:, uid: "google-123")
    OmniAuth::AuthHash.new(
      provider: "google_oauth2",
      uid: uid,
      info: {
        email: email,
        name: "Google Student",
        image: "https://example.com/google-student.jpg"
      }
    )
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
      utilities_included: true,
      available_from: Date.new(2026, 6, 1),
      available_until: Date.new(2026, 9, 30)
    }
  end
end
