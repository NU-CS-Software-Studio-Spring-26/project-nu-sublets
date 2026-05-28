require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  test "creates a session for a verified Northwestern Firebase token" do
    stub_firebase_token(
      "email" => "student@u.northwestern.edu",
      "email_verified" => true,
      "name" => "Test Student",
      "given_name" => "Test",
      "family_name" => "Student",
      "picture" => "https://example.com/test-student.jpg"
    ) do
      post session_path, params: { id_token: "firebase-token" }, as: :json
    end

    assert_response :success
    user = User.find_by!(email: "student@u.northwestern.edu")
    assert_equal "Test Student", user.name
    assert_equal "https://example.com/test-student.jpg", user.profile_photo_url
    assert user.confirmed?
  end

  test "rejects a verified non Northwestern Firebase token" do
    stub_firebase_token(
      "email" => "student@example.com",
      "email_verified" => true,
      "name" => "Test Student"
    ) do
      post session_path, params: { id_token: "firebase-token" }, as: :json
    end

    assert_response :forbidden
    assert_nil User.find_by(email: "student@example.com")
  end

  private

  def stub_firebase_token(decoded_token)
    verifier = Class.new do
      define_method(:verify) { |_id_token| decoded_token }
    end.new

    original_new = FirebaseTokenVerifier.method(:new)
    FirebaseTokenVerifier.define_singleton_method(:new) { |*| verifier }

    yield
  ensure
    FirebaseTokenVerifier.define_singleton_method(:new) { |*args, **kwargs| original_new.call(*args, **kwargs) }
  end
end
