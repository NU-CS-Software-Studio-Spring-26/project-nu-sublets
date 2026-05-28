require "test_helper"

class ListingQuestionTest < ActiveSupport::TestCase
  include ActiveSupport::Testing::TimeHelpers

  setup do
    travel_to Date.new(2026, 5, 1)
    @host = User.create!(name: "Host User", email: "host.user@u.northwestern.edu", active: true)
    @renter = User.create!(name: "Renter User", email: "renter.user@u.northwestern.edu", active: true)
    @listing = @host.sublet_listings.create!(valid_listing_params)
  end

  teardown do
    travel_back
  end

  test "valid with listing user and body" do
    question = @listing.listing_questions.new(user: @renter, body: "Is laundry included?")

    assert question.valid?
  end

  test "rejects blank and too long body" do
    blank_question = @listing.listing_questions.new(user: @renter, body: "   ")
    long_question = @listing.listing_questions.new(user: @renter, body: "a" * 501)

    assert_not blank_question.valid?
    assert_includes blank_question.errors[:body], "can't be blank"
    assert_not long_question.valid?
    assert_includes long_question.errors[:body], "is too long (maximum is 500 characters)"
  end

  test "rejects too long answer" do
    question = @listing.listing_questions.new(
      user: @renter,
      body: "Is parking available?",
      answer: "a" * 1_001
    )

    assert_not question.valid?
    assert_includes question.errors[:answer], "is too long (maximum is 1000 characters)"
  end

  test "normalizes body and answer text" do
    question = @listing.listing_questions.create!(
      user: @renter,
      body: "  Is\u0000 laundry\n included?  ",
      answer: "  Yes,\n laundry is included.  "
    )

    assert_equal "Is laundry included?", question.body
    assert_equal "Yes, laundry is included.", question.answer
    assert_not_nil question.answered_at
  end

  test "destroyed when listing is destroyed" do
    @listing.listing_questions.create!(user: @renter, body: "Is the room furnished?")

    assert_difference("ListingQuestion.count", -1) do
      @listing.destroy
    end
  end

  private

  def valid_listing_params
    {
      title: "Sunny Room Near Campus",
      description: "Clean furnished room within walking distance of campus.",
      price: 1200,
      address: "820 Noyes St, Evanston, IL 60201",
      bedrooms: 1,
      bathrooms: 1,
      furnished: true,
      pets_allowed: false,
      utilities_included: true,
      available_from: Date.current + 1.day,
      available_until: Date.current + 60.days
    }
  end
end
