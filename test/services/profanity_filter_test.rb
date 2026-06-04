require "test_helper"

class ProfanityFilterTest < ActiveSupport::TestCase
  test "allows clean text" do
    assert_not ProfanityFilter.contains_profanity?("Clean furnished room near campus.")
  end

  test "detects blocked words with punctuation and case differences" do
    assert ProfanityFilter.contains_profanity?("This place is Shit!")
  end

  test "does not match blocked words inside longer innocent words" do
    assert_not ProfanityFilter.contains_profanity?("A shell collection by the entryway.")
  end
end
