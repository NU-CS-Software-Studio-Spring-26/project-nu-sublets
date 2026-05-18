require "json"
require "net/http"

class AiListingDraftService
  class DraftError < StandardError; end
  class InputError < StandardError; end

  MAX_FIELD_LENGTH = 500
  DESCRIPTION_LIMIT = 1000
  TITLE_LIMIT = 100

  def self.call(params, api_key: ENV["OPENAI_API_KEY"], model: ENV.fetch("OPENAI_MODEL", "gpt-5.2"))
    new(params, api_key:, model:).call
  end

  def initialize(params, api_key:, model:)
    @params = normalize_params(params)
    @api_key = api_key.to_s.strip
    @model = model
  end

  def call
    raise InputError, "Add an address, rent, or notes before generating a draft." unless enough_context?

    return fallback_draft unless api_key.present?

    openai_draft
  rescue JSON::ParserError, KeyError, Net::OpenTimeout, Net::ReadTimeout, Errno::ECONNREFUSED, SocketError
    fallback_draft
  end

  private

  attr_reader :params, :api_key, :model

  def normalize_params(raw_params)
    raw_params.to_h.transform_values do |value|
      if value.is_a?(Array)
        value.map { |item| clean_text(item) }.reject(&:blank?).first(12)
      else
        clean_text(value)
      end
    end
  end

  def clean_text(value)
    value.to_s.encode("UTF-8", invalid: :replace, undef: :replace, replace: "")
         .gsub(/[[:cntrl:]]/, " ")
         .squish
         .first(MAX_FIELD_LENGTH)
  end

  def enough_context?
    [
      params["street-address"],
      params["price"],
      params["description"],
      params["amenities"],
      params["preferences"]
    ].any?(&:present?)
  end

  def openai_draft
    uri = URI("https://api.openai.com/v1/responses")
    request = Net::HTTP::Post.new(uri)
    request["Authorization"] = "Bearer #{api_key}"
    request["Content-Type"] = "application/json"
    request.body = JSON.generate(openai_payload)

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true, open_timeout: 4, read_timeout: 10) do |http|
      http.request(request)
    end

    return fallback_draft unless response.is_a?(Net::HTTPSuccess)

    parsed = JSON.parse(response.body)
    draft = JSON.parse(extract_output_text(parsed))
    title = clean_text(draft.fetch("title")).first(TITLE_LIMIT)
    description = clean_text(draft.fetch("description")).first(DESCRIPTION_LIMIT)

    return fallback_draft if title.blank? || description.blank?

    { title:, description:, source: "ai" }
  end

  def openai_payload
    {
      model:,
      instructions: "You help Northwestern students write accurate sublet listings. Do not invent amenities, dates, prices, or policies. Keep wording friendly and specific. Return only JSON.",
      input: prompt,
      max_output_tokens: 450,
      text: {
        format: {
          type: "json_schema",
          name: "sublet_listing_draft",
          strict: true,
          schema: {
            type: "object",
            additionalProperties: false,
            required: %w[title description],
            properties: {
              title: { type: "string", maxLength: TITLE_LIMIT },
              description: { type: "string", maxLength: DESCRIPTION_LIMIT }
            }
          }
        }
      }
    }
  end

  def prompt
    <<~PROMPT
      Create a sublet listing draft from these user-provided fields.

      Address: #{address}
      Rent: #{params["price"]}
      Dates: #{params["start-date"]} to #{params["end-date"]}
      Bedrooms: #{params["bedrooms"]}
      Bathrooms: #{params["bathrooms"]}
      Furnished: #{yes_no(params["furnished"])}
      Pets allowed: #{yes_no(params["pets_allowed"])}
      Utilities included: #{yes_no(params["utilities_included"])}
      Amenities: #{Array(params["amenities"]).join(", ")}
      Roommate preferences: #{Array(params["preferences"]).join(", ")}
      Existing notes: #{params["description"]}
    PROMPT
  end

  def extract_output_text(response_body)
    response_body.fetch("output").flat_map { |item| item.fetch("content", []) }
                 .filter_map { |content| content["text"] }
                 .join("\n")
  end

  def fallback_draft
    title = params["title"].presence || fallback_title
    description = params["description"].presence || fallback_description

    {
      title: title.first(TITLE_LIMIT),
      description: description.first(DESCRIPTION_LIMIT),
      source: "template"
    }
  end

  def fallback_title
    location = params["street-address"].presence || "Northwestern"
    room_label = params["bedrooms"].present? ? "#{params["bedrooms"]}-Bedroom " : ""
    "#{room_label}Sublet Near #{location}".squish
  end

  def fallback_description
    details = []
    details << "Available from #{params["start-date"]}" if params["start-date"].present?
    details << "through #{params["end-date"]}" if params["end-date"].present?
    details << "for $#{params["price"]}/month" if params["price"].present?
    details << "with #{Array(params["amenities"]).to_sentence}" if Array(params["amenities"]).any?
    details << "Utilities are included" if params["utilities_included"] == "1"
    details << "The space is furnished" if params["furnished"] == "1"

    sentence = details.any? ? details.join(" ") : "A comfortable sublet near Northwestern campus."
    "#{sentence}. Message me with any questions or to set up a time to see the space.".squish
  end

  def address
    [
      params["street-address"],
      params["address-line-2"],
      params["city"],
      params["state"],
      params["zip-code"]
    ].reject(&:blank?).join(", ")
  end

  def yes_no(value)
    value == "1" ? "Yes" : "No"
  end
end
