require "test_helper"

class SavedListingsAdviceControllerTest < ActionDispatch::IntegrationTest
  setup do
    @previous_api_key = ENV["OPENAI_API_KEY"]
    @user = User.create!(
      name: "Advisor User",
      email: "advisor.user@u.northwestern.edu",
      password: "password123",
      password_confirmation: "password123",
      confirmed_at: Time.current,
      active: true
    )
  end

  teardown do
    ENV["OPENAI_API_KEY"] = @previous_api_key
  end

  test "requires login" do
    post saved_listings_advice_path, params: {
      preferences: "quiet and furnished",
      listings: [ saved_listing ]
    }, as: :json

    assert_response :unauthorized
    assert_equal "You must be logged in.", response.parsed_body.fetch("error")
  end

  test "returns advice for signed in user" do
    sign_in(@user)

    fake_advisor = Class.new do
      def advise
        {
          summary: "Choose the studio.",
          top_listing_id: "listing-a",
          rankings: [
            {
              listing_id: "listing-a",
              title: "Sunny Studio",
              match_label: "Best fit",
              reasons: [ "Under budget" ],
              tradeoffs: []
            }
          ],
          next_steps: [ "Ask about utilities." ]
        }
      end
    end.new

    original_new = SavedListingsAdvisor.method(:new)
    SavedListingsAdvisor.define_singleton_method(:new) { |*| fake_advisor }

    begin
      post saved_listings_advice_path, params: {
        preferences: "quiet and furnished",
        listings: [ saved_listing ]
      }, as: :json
    ensure
      SavedListingsAdvisor.define_singleton_method(:new) { |*args, **kwargs| original_new.call(*args, **kwargs) }
    end

    assert_response :success
    advice = response.parsed_body.fetch("advice")
    assert_equal "Choose the studio.", advice.fetch("summary")
    assert_equal "listing-a", advice.fetch("top_listing_id")
    assert_equal "Under budget", advice.fetch("rankings").first.fetch("reasons").first
  end

  test "returns validation errors as unprocessable entity" do
    sign_in(@user)

    post saved_listings_advice_path, params: {
      preferences: "quiet",
      listings: []
    }, as: :json

    assert_response :unprocessable_entity
    assert_equal "Save at least one listing before asking for advice.", response.parsed_body.fetch("error")
  end

  test "returns inline unavailable error when OpenAI key is missing" do
    ENV["OPENAI_API_KEY"] = nil
    sign_in(@user)

    post saved_listings_advice_path, params: {
      preferences: "quiet and furnished",
      listings: [ saved_listing ]
    }, as: :json

    assert_response :success
    assert_equal "Add OPENAI_API_KEY to enable AI saved listing advice.", response.parsed_body.fetch("error")
    assert_equal true, response.parsed_body.fetch("unavailable")
  end

  private

  def sign_in(user)
    post session_path, params: { email: user.email, password: "password123" }
    assert_redirected_to profile_path
  end

  def saved_listing
    {
      id: "listing-a",
      title: "Sunny Studio",
      price: "$1,100/month",
      meta: [ "Studio", "1 bathroom", "Furnished" ],
      address: "820 Noyes St",
      href: "/listings/1"
    }
  end
end
