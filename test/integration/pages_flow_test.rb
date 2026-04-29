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

  test "home page links to the other product views" do
    get root_path

    assert_select "a[href='#{search_results_path}']", text: /Search/
    assert_select "a[href='#{post_sublet_path}']", text: /Post Sublet|Create a Posting/
    assert_select "a[href='#{listing_path}']"
  end

  test "search results page links into listing and home" do
    get search_results_path

    assert_select "a[href='#{root_path}']", text: /NU-Sublets/
    assert_select "a[href='#{listing_path}']"
    assert_select "a[href='#{post_sublet_path}']", text: /Post Sublet/
  end
end
