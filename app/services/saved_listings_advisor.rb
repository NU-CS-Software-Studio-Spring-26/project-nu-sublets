require "cgi"

class SavedListingsAdvisor
  MAX_LISTINGS = 10
  MAX_PREFERENCES_LENGTH = 1_000
  MAX_FIELD_LENGTH = 220
  DEFAULT_MODEL = "gpt-5-nano"
  DEFAULT_TIMEOUT = 28
  MAX_OUTPUT_TOKENS = 1_200

  AdviceUnavailable = Class.new(StandardError)
  ValidationError = Class.new(AdviceUnavailable)
  ConfigurationError = Class.new(AdviceUnavailable)

  def initialize(preferences:, listings:, client: nil)
    @preferences = preferences.to_s.squish.first(MAX_PREFERENCES_LENGTH)
    @listings = sanitize_listings(listings)
    @client = client
  end

  def advise
    raise ValidationError, "Save at least one listing before asking for advice." if listings.empty?
    raise ValidationError, "Add a few preferences so the advisor can compare your saved listings." if preferences.blank?

    normalize_advice(parse_with_openai)
  rescue AdviceUnavailable
    raise
  rescue StandardError => error
    Rails.logger.warn("[SavedListingsAdvisor] #{error.class}: #{error.message}")
    raise AdviceUnavailable, "OpenAI took too long to compare these listings. Please try again." if timeout_error?(error)

    raise AdviceUnavailable, "AI advice is unavailable right now. Please try again later."
  end

  private

  attr_reader :preferences, :listings, :client

  def parse_with_openai
    raise ConfigurationError, "Add OPENAI_API_KEY to enable AI saved listing advice." if ENV["OPENAI_API_KEY"].blank? && client.blank?

    response = openai_client.responses.create(
      model: ENV.fetch("OPENAI_ADVISOR_MODEL", DEFAULT_MODEL),
      input: [
        { role: :system, content: system_prompt },
        { role: :user, content: JSON.generate(preferences: preferences, listings: listings) }
      ],
      max_output_tokens: MAX_OUTPUT_TOKENS,
      reasoning: {
        effort: "minimal"
      },
      text: {
        verbosity: "low",
        format: {
          type: :json_schema,
          name: "SavedListingsAdvice",
          strict: true,
          schema: response_schema
        }
      },
      request_options: {
        max_retries: 0,
        timeout: request_timeout
      }
    )

    extract_response_advice(response)
  end

  def openai_client
    return client if client.present?

    require "openai"

    OpenAI::Client.new(
      api_key: ENV["OPENAI_API_KEY"],
      max_retries: 0,
      timeout: request_timeout
    )
  end

  def request_timeout
    Integer(ENV.fetch("OPENAI_ADVISOR_TIMEOUT", DEFAULT_TIMEOUT), exception: false) || DEFAULT_TIMEOUT
  end

  def timeout_error?(error)
    error.class.name.match?(/Timeout/) || error.message.match?(/timed out/i)
  end

  def extract_response_advice(response)
    output = Array(response_value(response, :output))
    content = output.flat_map { |item| Array(response_value(item, :content)) }

    parsed = content.find { |part| response_value(part, :parsed).present? }&.then { |part| response_value(part, :parsed) }
    return parsed.to_h if parsed.present? && parsed.respond_to?(:to_h)

    text = if response.respond_to?(:output_text)
             response.output_text
    else
             content.find { |part| response_value(part, :text).present? }&.then { |part| response_value(part, :text) }
    end

    text.present? ? JSON.parse(text) : {}
  end

  def normalize_advice(advice)
    advice = parameter_hash(advice).stringify_keys
    allowed_ids = listings.map { |listing| listing[:id] }

    rankings = Array(advice["rankings"]).filter_map do |ranking|
      ranking = parameter_hash(ranking).stringify_keys
      listing_id = ranking["listing_id"].to_s
      next unless allowed_ids.include?(listing_id)

      {
        listing_id: listing_id,
        title: clean_text(ranking["title"], max_length: 120).presence || listing_title(listing_id),
        match_label: clean_text(ranking["match_label"], max_length: 40).presence || "Good fit",
        reasons: clean_text_array(ranking["reasons"], limit: 3),
        tradeoffs: clean_text_array(ranking["tradeoffs"], limit: 3)
      }
    end

    raise AdviceUnavailable, "AI advice is unavailable right now. Please try again later." if rankings.empty?

    top_listing_id = advice["top_listing_id"].to_s
    top_listing_id = rankings.first[:listing_id] unless allowed_ids.include?(top_listing_id)

    {
      summary: clean_text(advice["summary"], max_length: 360).presence || "Here is the best fit based on your saved listings and preferences.",
      top_listing_id: top_listing_id,
      rankings: rankings,
      next_steps: clean_text_array(advice["next_steps"], limit: 3)
    }
  end

  def sanitize_listings(raw_listings)
    Array(raw_listings).first(MAX_LISTINGS).filter_map do |listing|
      listing = parameter_hash(listing).stringify_keys
      id = clean_text(listing["id"], max_length: 240)
      next if id.blank?

      {
        id: id,
        title: clean_text(listing["title"], max_length: 120),
        price: clean_text(listing["price"], max_length: 40),
        meta: clean_text_array(listing["meta"], limit: 5, max_length: 80),
        address: clean_text(listing["address"], max_length: 160),
        href: clean_text(listing["href"], max_length: 160)
      }
    end
  end

  def clean_text(value, max_length: MAX_FIELD_LENGTH)
    CGI.unescapeHTML(ActionController::Base.helpers.strip_tags(value.to_s)).squish.first(max_length)
  end

  def clean_text_array(values, limit:, max_length: MAX_FIELD_LENGTH)
    Array(values).filter_map { |value| clean_text(value, max_length: max_length).presence }.first(limit)
  end

  def listing_title(listing_id)
    listings.find { |listing| listing[:id] == listing_id }&.dig(:title).presence || "Saved listing"
  end

  def parameter_hash(value)
    if value.respond_to?(:to_unsafe_h)
      value.to_unsafe_h
    elsif value.respond_to?(:to_h)
      value.to_h
    else
      {}
    end
  end

  def response_value(object, key)
    return object[key] if object.respond_to?(:key?) && object.key?(key)
    return object[key.to_s] if object.respond_to?(:key?) && object.key?(key.to_s)
    return object.public_send(key) if object.respond_to?(key)

    nil
  end

  def system_prompt
    <<~PROMPT.squish
      You are helping a Northwestern student compare saved sublet listings.
      Use only the listing facts and preferences provided. Do not invent missing details.
      Do not suggest date flexibility, negotiability, or amenities unless the listing facts state them.
      Rank the listings by fit, explain concrete reasons, note tradeoffs, and suggest practical next steps.
      Keep the response very short: one sentence summary, at most two reasons per listing, one tradeoff per listing, and two next steps.
    PROMPT
  end

  def response_schema
    {
      type: "object",
      properties: {
        summary: { type: "string" },
        top_listing_id: { type: "string" },
        rankings: {
          type: "array",
          maxItems: MAX_LISTINGS,
          items: {
            type: "object",
            properties: {
              listing_id: { type: "string" },
              title: { type: "string" },
              match_label: { type: "string" },
              reasons: { type: "array", maxItems: 2, items: { type: "string" } },
              tradeoffs: { type: "array", maxItems: 1, items: { type: "string" } }
            },
            required: %w[listing_id title match_label reasons tradeoffs],
            additionalProperties: false
          }
        },
        next_steps: { type: "array", maxItems: 2, items: { type: "string" } }
      },
      required: %w[summary top_listing_id rankings next_steps],
      additionalProperties: false
    }
  end
end
