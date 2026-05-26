require "test_helper"

class NaturalSearchParserTest < ActiveSupport::TestCase
  setup do
    @previous_api_key = ENV["OPENAI_API_KEY"]
    @previous_model = ENV["OPENAI_SEARCH_MODEL"]
    @cache = ActiveSupport::Cache::MemoryStore.new
  end

  teardown do
    ENV["OPENAI_API_KEY"] = @previous_api_key
    ENV["OPENAI_SEARCH_MODEL"] = @previous_model
  end

  test "uses local fallback parser when OpenAI API key is not configured" do
    ENV["OPENAI_API_KEY"] = nil

    filters = NaturalSearchParser.new(
      "furnished studio under $1,200 near campus 06/01/2026 08/31/2026 quiet",
      cache: @cache
    ).parse

    assert_equal "0", filters["bedrooms"]
    assert_equal "1200", filters["max_price"]
    assert_equal "06/01/2026", filters["move-in"]
    assert_equal "08/31/2026", filters["move-out"]
    assert_equal "campus", filters["query"]
    assert_includes filters["amenities"], "Furnished"
    assert_includes filters["preferences"], "Quiet"
  end

  test "falls back cleanly when OpenAI returns an unusable response" do
    ENV["OPENAI_API_KEY"] = "test-key"
    client = FakeOpenAIClient.new({})

    filters = NaturalSearchParser.new("1 bed under 900 with laundry", client: client, cache: @cache).parse

    assert_equal "1", filters["bedrooms"]
    assert_equal "900", filters["max_price"]
    assert_equal [ "Laundry" ], filters["amenities"]
  end

  test "normalizes OpenAI filters and discards unsupported labels" do
    ENV["OPENAI_API_KEY"] = "test-key"
    client = FakeOpenAIClient.new(
      output: [
        {
          content: [
            {
              text: {
                "max_price" => "1300",
                "amenities" => [ "laundry", "Made-up amenity" ],
                "preferences" => [ "quiet", "Made-up preference" ]
              }.to_json
            }
          ]
        }
      ]
    )

    filters = NaturalSearchParser.new("quiet place with laundry under 1300", client: client, cache: @cache).parse

    assert_equal "1300", filters["max_price"]
    assert_equal [ "Laundry" ], filters["amenities"]
    assert_equal [ "Quiet" ], filters["preferences"]
  end

  private

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
end
