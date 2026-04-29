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

  test "post sublet form submits to an app endpoint" do
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
end
