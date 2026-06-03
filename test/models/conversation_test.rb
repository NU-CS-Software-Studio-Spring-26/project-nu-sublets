require "test_helper"

class ConversationTest < ActiveSupport::TestCase
  setup do
    @initiator = User.create!(name: "Initiator", email: "initiator@u.northwestern.edu", active: true, confirmed_at: Time.current)
    @recipient = User.create!(name: "Recipient", email: "recipient@u.northwestern.edu", active: true, confirmed_at: Time.current)
  end

  test "builds the same key regardless of participant order" do
    first = Conversation.between(@initiator, @recipient)
    second = Conversation.between(@recipient, @initiator)

    assert_equal first.conversation_key, second.conversation_key
  end

  test "rejects self conversations" do
    conversation = Conversation.between(@initiator, @initiator)

    assert_not conversation.valid?
    assert_includes conversation.errors[:recipient], "must be a different student"
  end

  test "rejects unconfirmed participants" do
    unconfirmed = User.create!(name: "Unconfirmed", email: "unconfirmed@u.northwestern.edu", active: true)
    conversation = Conversation.between(@initiator, unconfirmed)

    assert_not conversation.valid?
    assert_includes conversation.errors[:base], "Participants must be verified Northwestern students"
  end

  test "finds conversations involving a user" do
    included = Conversation.between(@initiator, @recipient)
    included.save!
    other = User.create!(name: "Other", email: "other@u.northwestern.edu", active: true, confirmed_at: Time.current)
    excluded = Conversation.between(@recipient, other)
    excluded.save!

    assert_includes @initiator.conversations, included
    assert_not_includes @initiator.conversations, excluded
  end
end
