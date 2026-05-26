class NaturalSearchParser
  MAX_QUERY_LENGTH = 500
  CACHE_TTL = 24.hours
  DEFAULT_MODEL = "gpt-5-nano"

  FILTER_KEYS = %w[
    query
    move-in
    move-out
    min_price
    max_price
    bedrooms
    bathrooms
    amenities
    preferences
  ].freeze

  def initialize(query, client: nil, cache: Rails.cache)
    @query = query.to_s.squish.first(MAX_QUERY_LENGTH)
    @client = client
    @cache = cache
  end

  def parse
    return {} if query.blank? || query.length < 3

    normalize_filters(cached_or_parse)
  rescue StandardError
    fallback_filters
  end

  private

  attr_reader :query, :client, :cache

  def cached_or_parse
    cache.fetch(cache_key, expires_in: CACHE_TTL) do
      parse_with_openai.presence || fallback_filters
    end
  end

  def cache_key
    "natural_search_parser/#{Date.current.iso8601}/#{Digest::SHA256.hexdigest(query.downcase)}"
  end

  def parse_with_openai
    return {} if ENV["OPENAI_API_KEY"].blank?

    response = openai_client.responses.create(
      model: ENV.fetch("OPENAI_SEARCH_MODEL", DEFAULT_MODEL),
      input: [
        { role: :system, content: system_prompt },
        { role: :user, content: query }
      ],
      text: {
        format: {
          type: :json_schema,
          name: "SubletSearchFilters",
          strict: true,
          schema: response_schema
        }
      },
      request_options: {
        max_retries: 0,
        timeout: 3
      }
    )

    extract_response_filters(response)
  end

  def openai_client
    @openai_client ||= begin
      require "openai"

      client || OpenAI::Client.new(
        api_key: ENV["OPENAI_API_KEY"],
        max_retries: 0,
        timeout: 3
      )
    end
  end

  def extract_response_filters(response)
    output = Array(response.respond_to?(:output) ? response.output : response[:output])
    content = output.flat_map { |item| Array(item.respond_to?(:content) ? item.content : item[:content]) }

    parsed = content.find { |part| part.respond_to?(:parsed) && part.parsed.present? }&.parsed
    return parsed.to_h if parsed.respond_to?(:to_h)

    text = if response.respond_to?(:output_text)
             response.output_text
    else
             content.find { |part| part.respond_to?(:text) || part[:text].present? }&.then { |part| part.respond_to?(:text) ? part.text : part[:text] }
    end

    text.present? ? JSON.parse(text) : {}
  end

  def system_prompt
    <<~PROMPT.squish
      Extract search filters for a Northwestern student sublet marketplace.
      Return only fields supported by the schema. Use MM/DD/YYYY for dates.
      Put location or unmatched descriptive terms in query only when they are useful for text search.
      Do not invent details that are not implied by the user.
    PROMPT
  end

  def response_schema
    {
      type: "object",
      properties: {
        query: { type: %w[string null] },
        "move-in": { type: %w[string null] },
        "move-out": { type: %w[string null] },
        min_price: { type: %w[string null] },
        max_price: { type: %w[string null] },
        bedrooms: { type: %w[string null] },
        bathrooms: { type: %w[string null] },
        amenities: {
          type: "array",
          items: { type: "string", enum: SubletListing::AMENITY_OPTIONS }
        },
        preferences: {
          type: "array",
          items: { type: "string", enum: SubletListing::PREFERENCE_OPTIONS }
        }
      },
      required: FILTER_KEYS,
      additionalProperties: false
    }
  end

  def fallback_filters
    filters = {}
    normalized_query = query.downcase

    filters["max_price"] = price_match(normalized_query, /\b(?:under|below|less than|max|maximum|up to)\s*\$?\s*([\d,]+)/)
    filters["min_price"] = price_match(normalized_query, /\b(?:over|above|more than|min|minimum|at least)\s*\$?\s*([\d,]+)/)

    if (range = normalized_query.match(/\bbetween\s+\$?\s*([\d,]+)\s+(?:and|-|to)\s+\$?\s*([\d,]+)/))
      filters["min_price"] = number_string(range[1])
      filters["max_price"] = number_string(range[2])
    end

    filters["bedrooms"] = "0" if normalized_query.match?(/\bstudio\b/)
    filters["bedrooms"] ||= room_count(normalized_query, /(\d+)\s*(?:bed|bedroom|br)\b/)
    filters["bathrooms"] = room_count(normalized_query, /(\d+)\s*(?:bath|bathroom|ba)\b/)
    filters["amenities"] = matching_labels(SubletListing::AMENITY_OPTIONS, normalized_query)
    filters["preferences"] = matching_labels(SubletListing::PREFERENCE_OPTIONS, normalized_query)
    filters.merge!(date_filters(normalized_query))
    filters["query"] = location_query(normalized_query)

    normalize_filters(filters)
  end

  def price_match(text, pattern)
    match = text.match(pattern)
    number_string(match[1]) if match
  end

  def room_count(text, pattern)
    match = text.match(pattern)
    match[1] if match
  end

  def number_string(value)
    value.to_s.delete(",")
  end

  def matching_labels(labels, text)
    labels.select { |label| text.include?(label.downcase) }
  end

  def date_filters(text)
    dates = text.scan(%r{\b\d{1,2}/\d{1,2}/\d{4}\b}).first(2)
    {
      "move-in" => dates[0],
      "move-out" => dates[1]
    }.compact
  end

  def location_query(text)
    return "campus" if text.match?(/\b(?:near|by|close to|walk to)\s+(?:campus|northwestern)\b/)
    return "evanston" if text.include?("evanston")

    nil
  end

  def normalize_filters(filters)
    filters = filters.to_h.stringify_keys.slice(*FILTER_KEYS)
    filters["amenities"] = allowed_values(filters["amenities"], SubletListing::AMENITY_OPTIONS)
    filters["preferences"] = allowed_values(filters["preferences"], SubletListing::PREFERENCE_OPTIONS)

    filters.each_with_object({}) do |(key, value), normalized|
      next if value.blank?

      normalized[key] = value.is_a?(Array) ? value : value.to_s
    end
  end

  def allowed_values(values, allowed)
    Array(values).filter_map do |value|
      allowed.find { |label| label.casecmp?(value.to_s) }
    end.uniq
  end
end
