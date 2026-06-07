require "json"
require "net/http"

class GoogleGeocodingClient
  ENDPOINT = "https://maps.googleapis.com/maps/api/geocode/json"
  Result = Struct.new(:success?, :latitude, :longitude, :status, :error, keyword_init: true)

  def initialize(api_key: ENV["GOOGLE_MAPS_GEOCODING_API_KEY"])
    @api_key = api_key.to_s
  end

  def geocode(address)
    return failure("missing_key", "Google Maps API key is not configured") if api_key.blank?
    return failure("blank_address", "Address is blank") if address.blank?

    response = Net::HTTP.get_response(uri_for(address))
    return failure("http_error", "Geocoding request failed with HTTP #{response.code}") unless response.is_a?(Net::HTTPSuccess)

    parse_response(JSON.parse(response.body))
  rescue JSON::ParserError
    failure("invalid_response", "Geocoding response was not valid JSON")
  rescue StandardError => error
    failure("request_failed", error.message)
  end

  private

  attr_reader :api_key

  def uri_for(address)
    uri = URI(ENDPOINT)
    uri.query = URI.encode_www_form(
      address: address,
      key: api_key,
      components: "locality:Evanston|administrative_area:IL|country:US"
    )
    uri
  end

  def parse_response(body)
    status = body["status"].to_s
    result = Array(body["results"]).first
    location = result&.dig("geometry", "location")

    if status == "OK" && location
      Result.new(
        success?: true,
        latitude: BigDecimal(location.fetch("lat").to_s),
        longitude: BigDecimal(location.fetch("lng").to_s),
        status: "geocoded"
      )
    else
      failure(status.presence || "no_results", body["error_message"].presence || "No geocoding result found")
    end
  end

  def failure(status, error)
    Result.new(success?: false, status: status, error: error)
  end
end
