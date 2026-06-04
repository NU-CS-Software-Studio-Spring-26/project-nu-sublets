require "yaml"

class ProfanityFilter
  CONFIG_PATH = Rails.root.join("config/profanity_words.yml")
  ERROR_MESSAGE = "Please remove inappropriate language before submitting."

  class << self
    def contains_profanity?(value)
      text = value.to_s
      return false if text.blank?

      blocked_word_patterns.any? { |pattern| pattern.match?(text) }
    end

    def blocked_words
      @blocked_words ||= begin
        config = YAML.safe_load_file(CONFIG_PATH, aliases: false) || {}
        Array(config["blocked_words"])
          .map { |word| word.to_s.downcase.strip }
          .reject(&:blank?)
          .uniq
      end
    end

    def reset!
      @blocked_words = nil
      @blocked_word_patterns = nil
    end

    private

    def blocked_word_patterns
      @blocked_word_patterns ||= blocked_words.map do |word|
        escaped = Regexp.escape(word).gsub("\\ ", "\\s+")
        /(?<![[:alnum:]_])#{escaped}(?![[:alnum:]_])/i
      end
    end
  end
end
