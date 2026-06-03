require "test_helper"

class ConversationChannelTest < ActionCable::Channel::TestCase
  setup do
    @initiator = User.create!(name: "Channel Initiator", email: "channel.initiator@u.northwestern.edu", active: true, confirmed_at: Time.current)
    @recipient = User.create!(name: "Channel Recipient", email: "channel.recipient@u.northwestern.edu", active: true, confirmed_at: Time.current)
    @conversation = Conversation.between(@initiator, @recipient)
    @conversation.save!
  end

  test "participant subscribes to conversation stream" do
    stub_connection current_user: @initiator

    subscribe conversation_id: @conversation.id

    assert subscription.confirmed?
    assert_has_stream_for @conversation
  end

  test "outsider cannot subscribe" do
    outsider = User.create!(name: "Channel Outsider", email: "channel.outsider@u.northwestern.edu", active: true, confirmed_at: Time.current)
    stub_connection current_user: outsider

    subscribe conversation_id: @conversation.id

    assert subscription.rejected?
  end
end
