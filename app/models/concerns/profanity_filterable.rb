module ProfanityFilterable
  extend ActiveSupport::Concern

  class_methods do
    def validates_no_profanity_in(*attributes)
      validate do
        if attributes.any? { |attribute| ProfanityFilter.contains_profanity?(public_send(attribute)) }
          errors.add(:base, ProfanityFilter::ERROR_MESSAGE)
        end
      end
    end
  end
end
