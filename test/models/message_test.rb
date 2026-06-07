require "test_helper"

class MessageTest < ActiveSupport::TestCase
  setup do
    @initiator = User.create!(name: "Initiator", email: "message.initiator@u.northwestern.edu", active: true, confirmed_at: Time.current)
    @recipient = User.create!(name: "Recipient", email: "message.recipient@u.northwestern.edu", active: true, confirmed_at: Time.current)
    @conversation = Conversation.between(@initiator, @recipient)
    @conversation.save!
  end

  test "validates body" do
    blank = @conversation.messages.new(sender: @initiator, body: "   ")
    long = @conversation.messages.new(sender: @initiator, body: "a" * 1_001)

    assert_not blank.valid?
    assert_includes blank.errors[:body], "can't be blank"
    assert_not long.valid?
    assert_includes long.errors[:body], "is too long (maximum is 1000 characters)"
  end

  test "normalizes message body" do
    message = @conversation.messages.create!(sender: @initiator, body: "  Hello\u0000 there\nnow  ")

    assert_equal "Hello there now", message.body
  end

  test "rejects profanity in message body" do
    message = @conversation.messages.new(sender: @initiator, body: "This message is shit.")

    assert_not message.valid?
    assert_includes message.errors[:base], ProfanityFilter::ERROR_MESSAGE
  end

  test "sender must be a participant" do
    outsider = User.create!(name: "Outsider", email: "message.outsider@u.northwestern.edu", active: true, confirmed_at: Time.current)
    message = @conversation.messages.new(sender: outsider, body: "Can I join?")

    assert_not message.valid?
    assert_includes message.errors[:sender], "must be a conversation participant"
  end

  test "broadcast timestamp uses central time with CT label" do
    travel_to Time.utc(2026, 6, 8, 1, 27, 0) do
      message = @conversation.messages.create!(sender: @initiator, body: "Central timestamp")
      captured_conversation = nil
      captured_payload = nil
      original_broadcast_to = ConversationChannel.method(:broadcast_to)
      ConversationChannel.define_singleton_method(:broadcast_to) do |conversation, payload|
        captured_conversation = conversation
        captured_payload = payload
      end

      begin
        message.send(:broadcast_to_conversation)
      ensure
        ConversationChannel.define_singleton_method(:broadcast_to) do |conversation, payload|
          original_broadcast_to.call(conversation, payload)
        end
      end

      assert_equal @conversation, captured_conversation
      assert_equal(
        {
          id: message.id,
          sender_id: @initiator.id,
          sender_name: @initiator.display_name,
          body: "Central timestamp",
          created_at: "Jun 7, 2026 8:27 PM CT",
          created_at_iso: "2026-06-08T01:27:00Z"
        },
        captured_payload
      )
    end
  end
end
