require "test_helper"

class MessageTest < ActiveSupport::TestCase
  include ActiveSupport::Testing::TimeHelpers

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

  test "broadcasts created_at in central time with label" do
    broadcast_payload = nil
    timestamp = Time.utc(2026, 5, 1, 1, 30, 0)

    travel_to(timestamp) do
      ConversationChannel.stub(:broadcast_to, ->(_conversation, payload) { broadcast_payload = payload }) do
        @conversation.messages.create!(sender: @initiator, body: "Hello there")
      end
    end

    assert_equal "Apr 30, 2026 8:30 PM CT", broadcast_payload[:created_at]
  end
end
