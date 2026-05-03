require "test_helper"

class PagesFlowTest < ActionDispatch::IntegrationTest
  test "home page is reachable" do
    get root_path

    assert_response :success
  end

  test "listing page is reachable" do
    get listing_path

    assert_response :success
  end

  test "search results page is reachable" do
    get search_results_path

    assert_response :success
  end

  test "post sublet page is reachable" do
    get post_sublet_path

    assert_response :success
  end

  test "login page is reachable" do
    get login_path

    assert_response :success
  end

  test "login page redirects after sign in" do
    sign_in_with_firebase_email("student@u.northwestern.edu")

    get login_path

    assert_redirected_to profile_path
  end

  test "post sublet form requires login" do
    post submit_sublet_path, params: {
      "street-address" => "820 Noyes St",
      "city" => "Evanston",
      "state" => "IL",
      "zip-code" => "60201",
      "price" => "850"
    }

    assert_redirected_to login_path
  end

  test "logged in post sublet form submits to an app endpoint" do
    sign_in_with_firebase_email("student@u.northwestern.edu")

    post submit_sublet_path, params: {
      "street-address" => "820 Noyes St",
      "city" => "Evanston",
      "state" => "IL",
      "zip-code" => "60201",
      "price" => "850"
    }

    assert_redirected_to listing_path
  end

  test "home page links to the other product views" do
    get root_path

    assert_select "a[href='#{search_results_path}']", text: /Search/
    assert_select "a[href='#{post_sublet_path}']", text: /Post Sublet|Create a Posting/
    assert_select "a[href='#{login_path}']", text: /Log in/
    assert_select "a[href='#{listing_path}']"
  end

  test "signed in navigation shows the current user and logout" do
    sign_in_with_firebase_email("student@u.northwestern.edu")

    get root_path

    assert_response :success
    assert_select "a[href='#{profile_path}']", text: "Profile"
    assert_select "form[action='#{session_path}'] button", text: "Log out"
    assert_select "a[data-login-trigger]", text: "Create a Posting", count: 0
    assert_select "a[href='#{post_sublet_path}']", text: "Create a Posting"
  end

  test "profile page is tailored to the signed in user" do
    sign_in_with_firebase_email("student@u.northwestern.edu")

    get profile_path

    assert_response :success
    assert_select "h1", text: "Test Student"
    assert_includes response.body, "student@u.northwestern.edu"
    assert_includes response.body, "Hi Test"
    assert_select "a[href='#{post_sublet_path}']", text: "Post a Sublet"
  end

  test "search results page links into listing and home" do
    get search_results_path

    assert_select "a[href='#{root_path}']", text: /NU-Sublets/
    assert_select "a[href='#{listing_path}']"
    assert_select "a[href='#{post_sublet_path}']", text: /Post Sublet/
  end

  test "post sublet page uses the submit endpoint" do
    get post_sublet_path

    assert_select "form[action='#{submit_sublet_path}'][method='post']"
  end

  private

  def sign_in_with_firebase_email(email)
    verifier = Class.new do
      define_method(:verify) do |_id_token|
        {
          "email" => email,
          "email_verified" => true,
          "name" => "Test Student"
        }
      end
    end.new

    original_new = FirebaseTokenVerifier.method(:new)
    FirebaseTokenVerifier.define_singleton_method(:new) { |*| verifier }

    post session_path, params: { id_token: "firebase-token" }, as: :json
  ensure
    FirebaseTokenVerifier.define_singleton_method(:new) { |*args, **kwargs| original_new.call(*args, **kwargs) }
  end
end
