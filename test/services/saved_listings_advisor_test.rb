require "test_helper"

class SavedListingsAdvisorTest < ActiveSupport::TestCase
  setup do
    @previous_api_key = ENV["OPENAI_API_KEY"]
    @previous_model = ENV["OPENAI_ADVISOR_MODEL"]
    ENV["OPENAI_API_KEY"] = "test-key"
  end

  teardown do
    ENV["OPENAI_API_KEY"] = @previous_api_key
    ENV["OPENAI_ADVISOR_MODEL"] = @previous_model
  end

  test "returns normalized advice from OpenAI response" do
    client = FakeOpenAIClient.new(
      output: [
        {
          content: [
            {
              text: {
                "summary" => "Listing A is the best fit.",
                "top_listing_id" => "listing-a",
                "rankings" => [
                  {
                    "listing_id" => "listing-a",
                    "title" => "Sunny Studio",
                    "match_label" => "Best fit",
                    "reasons" => [ "Under budget", "Furnished" ],
                    "tradeoffs" => [ "Parking is not listed" ]
                  },
                  {
                    "listing_id" => "unknown-listing",
                    "title" => "Unsupported",
                    "match_label" => "Ignore",
                    "reasons" => [ "Not saved" ],
                    "tradeoffs" => []
                  }
                ],
                "next_steps" => [ "Ask the host about utilities." ]
              }.to_json
            }
          ]
        }
      ]
    )

    advice = SavedListingsAdvisor.new(
      preferences: "under $1200, furnished, quiet",
      listings: saved_listings,
      client: client
    ).advise

    assert_equal "Listing A is the best fit.", advice[:summary]
    assert_equal "listing-a", advice[:top_listing_id]
    assert_equal 1, advice[:rankings].size
    assert_equal "Sunny Studio", advice[:rankings].first[:title]
    assert_equal [ "Under budget", "Furnished" ], advice[:rankings].first[:reasons]
    assert_equal [ "Ask the host about utilities." ], advice[:next_steps]
  end

  test "requires saved listings" do
    error = assert_raises(SavedListingsAdvisor::AdviceUnavailable) do
      SavedListingsAdvisor.new(preferences: "quiet", listings: [], client: FakeOpenAIClient.new({})).advise
    end

    assert_equal "Save at least one listing before asking for advice.", error.message
  end

  test "requires preferences" do
    error = assert_raises(SavedListingsAdvisor::AdviceUnavailable) do
      SavedListingsAdvisor.new(preferences: "", listings: saved_listings, client: FakeOpenAIClient.new({})).advise
    end

    assert_equal "Add a few preferences so the advisor can compare your saved listings.", error.message
  end

  test "requires API key when no client is injected" do
    ENV["OPENAI_API_KEY"] = nil

    error = assert_raises(SavedListingsAdvisor::AdviceUnavailable) do
      SavedListingsAdvisor.new(preferences: "quiet", listings: saved_listings).advise
    end

    assert_equal "Add OPENAI_API_KEY to enable AI saved listing advice.", error.message
  end

  test "falls back when response has no usable saved listing rankings" do
    client = FakeOpenAIClient.new(
      output: [
        {
          content: [
            {
              text: {
                "summary" => "No match.",
                "top_listing_id" => "missing",
                "rankings" => [
                  {
                    "listing_id" => "missing",
                    "title" => "Missing",
                    "match_label" => "No match",
                    "reasons" => [],
                    "tradeoffs" => []
                  }
                ],
                "next_steps" => []
              }.to_json
            }
          ]
        }
      ]
    )

    error = assert_raises(SavedListingsAdvisor::AdviceUnavailable) do
      SavedListingsAdvisor.new(preferences: "quiet", listings: saved_listings, client: client).advise
    end

    assert_equal "AI advice is unavailable right now. Please try again later.", error.message
  end

  test "limits listing payload sent to OpenAI" do
    client = CapturingOpenAIClient.new(valid_response_for("listing-1"))
    listings = 12.times.map do |index|
      { "id" => "listing-#{index + 1}", "title" => "Listing #{index + 1}", "price" => "$#{900 + index}" }
    end

    SavedListingsAdvisor.new(preferences: "quiet furnished", listings: listings, client: client).advise

    user_payload = JSON.parse(client.input.last.fetch(:content))

    assert_equal 10, user_payload.fetch("listings").size
    assert_equal "listing-10", user_payload.fetch("listings").last.fetch("id")
  end

  private

  def saved_listings
    [
      {
        "id" => "listing-a",
        "title" => "Sunny Studio",
        "price" => "$1,100/month",
        "meta" => [ "Studio", "1 bathroom", "Furnished" ],
        "address" => "820 Noyes St",
        "href" => "/listings/1"
      },
      {
        "id" => "listing-b",
        "title" => "Two Bed",
        "price" => "$1,500/month",
        "meta" => [ "2 bedrooms", "1 bathroom" ],
        "address" => "900 Foster St",
        "href" => "/listings/2"
      }
    ]
  end

  def valid_response_for(listing_id)
    {
      output: [
        {
          content: [
            {
              text: {
                "summary" => "Best fit.",
                "top_listing_id" => listing_id,
                "rankings" => [
                  {
                    "listing_id" => listing_id,
                    "title" => "Listing",
                    "match_label" => "Best fit",
                    "reasons" => [ "Matches preferences" ],
                    "tradeoffs" => []
                  }
                ],
                "next_steps" => []
              }.to_json
            }
          ]
        }
      ]
    }
  end

  class FakeOpenAIClient
    def initialize(response)
      @response = response
    end

    def responses
      self
    end

    def create(**)
      @response
    end
  end

  class CapturingOpenAIClient < FakeOpenAIClient
    attr_reader :input

    def create(input:, **)
      @input = input
      super
    end
  end
end
