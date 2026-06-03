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

  test "sender must be a participant" do
    outsider = User.create!(name: "Outsider", email: "message.outsider@u.northwestern.edu", active: true, confirmed_at: Time.current)
    message = @conversation.messages.new(sender: outsider, body: "Can I join?")

    assert_not message.valid?
    assert_includes message.errors[:sender], "must be a conversation participant"
  end
end
