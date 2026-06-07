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

  test "allows conversations with existing Northwestern account holders" do
    account_holder = User.create!(name: "Account Holder", email: "account.holder@u.northwestern.edu", active: true)
    conversation = Conversation.between(@initiator, account_holder)

    assert conversation.valid?
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

  test "tracks unread messages and marks conversations read for participants" do
    conversation = Conversation.between(@initiator, @recipient)
    conversation.save!
    conversation.messages.create!(sender: @initiator, body: "Hello")

    assert conversation.unread_for?(@recipient)
    assert_not conversation.unread_for?(@initiator)
    assert_equal 1, conversation.unread_message_count_for(@recipient)

    conversation.mark_as_read_for(@recipient)

    assert_not conversation.unread_for?(@recipient)
    assert_equal 0, conversation.unread_message_count_for(@recipient)
  end

  test "unread_conversations_count returns only conversations with unread messages" do
    other = User.create!(name: "Other", email: "other@u.northwestern.edu", active: true, confirmed_at: Time.current)
    conversation = Conversation.between(@initiator, @recipient)
    conversation.save!
    conversation.messages.create!(sender: @initiator, body: "Hello")

    direct = Conversation.between(@initiator, other)
    direct.save!
    direct.messages.create!(sender: @initiator, body: "Hi")

    assert_equal 1, @recipient.unread_conversations_count
    assert_equal 0, @initiator.unread_conversations_count
  end
end
