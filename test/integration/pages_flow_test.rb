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
end
