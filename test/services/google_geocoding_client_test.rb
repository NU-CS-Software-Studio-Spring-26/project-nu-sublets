require "test_helper"

class GoogleGeocodingClientTest < ActiveSupport::TestCase
  test "returns missing key failure without making a request" do
    result = GoogleGeocodingClient.new(api_key: "").geocode("820 Noyes St, Evanston, IL 60201")

    assert_not result.success?
    assert_equal "missing_key", result.status
  end

  test "parses successful geocoding response" do
    response = Net::HTTPOK.new("1.1", "200", "OK")
    set_response_body(response, {
      status: "OK",
      results: [
        {
          geometry: {
            location: {
              lat: 42.0583,
              lng: -87.6831
            }
          }
        }
      ]
    }.to_json)

    with_http_response(response) do
      result = GoogleGeocodingClient.new(api_key: "test-key").geocode("820 Noyes St, Evanston, IL 60201")

      assert result.success?
      assert_equal BigDecimal("42.0583"), result.latitude
      assert_equal BigDecimal("-87.6831"), result.longitude
      assert_equal "geocoded", result.status
    end
  end

  test "returns api status when geocoding has no result" do
    response = Net::HTTPOK.new("1.1", "200", "OK")
    set_response_body(response, { status: "ZERO_RESULTS", results: [] }.to_json)

    with_http_response(response) do
      result = GoogleGeocodingClient.new(api_key: "test-key").geocode("Unknown address")

      assert_not result.success?
      assert_equal "ZERO_RESULTS", result.status
    end
  end

  private

  def with_http_response(response)
    original_get_response = Net::HTTP.method(:get_response)
    Net::HTTP.define_singleton_method(:get_response) { |_uri| response }
    yield
  ensure
    Net::HTTP.define_singleton_method(:get_response) { |*args, **kwargs| original_get_response.call(*args, **kwargs) }
  end

  def set_response_body(response, body)
    response.instance_variable_set(:@body, body)
    response.instance_variable_set(:@read, true)
  end
end
