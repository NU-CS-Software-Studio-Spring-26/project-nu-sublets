require "test_helper"

class ConversationsTest < ActionDispatch::IntegrationTest
  include ActiveSupport::Testing::TimeHelpers

  setup do
    travel_to Time.zone.local(2026, 5, 1, 12, 0, 0)
    @host = User.create!(
      name: "Chat Host",
      email: "chat.host@u.northwestern.edu",
      active: true,
      confirmed_at: Time.current,
      phone_number: "+1 (847) 555-1200"
    )
    @listing = @host.sublet_listings.create!(valid_listing_attributes)
  end

  teardown do
    travel_back
  end

  test "signed out users cannot view conversations" do
    get conversations_path

    assert_redirected_to login_path
  end

  test "signed in user can start a listing conversation" do
    sign_in_with_firebase_email("chat.renter@u.northwestern.edu")

    assert_difference("Conversation.count", 1) do
      post conversations_path, params: { recipient_id: @host.id, sublet_listing_id: @listing.id }
    end

    conversation = Conversation.order(:created_at).last
    assert_equal @listing, conversation.sublet_listing
    assert_redirected_to conversation_path(conversation)
  end

  test "starting the same conversation reuses it" do
    sign_in_with_firebase_email("chat.reuse@u.northwestern.edu")

    assert_difference("Conversation.count", 1) do
      post conversations_path, params: { recipient_id: @host.id, sublet_listing_id: @listing.id }
      post conversations_path, params: { recipient_id: @host.id, sublet_listing_id: @listing.id }
    end
  end

  test "signed in user can view inbox with an existing conversation" do
    renter = sign_in_with_firebase_email("chat.inbox@u.northwestern.edu")
    conversation = Conversation.between(renter, @host, listing: @listing)
    conversation.save!
    conversation.messages.create!(
      sender: @host,
      body: "The room is still available.",
      created_at: Time.utc(2026, 6, 8, 1, 18, 0)
    )

    get conversations_path

    assert_response :success
    assert_select "a[aria-label='Open conversation with Chat Host'][href='#{conversation_path(conversation)}']"
    assert_select ".conversation-list-context", text: @listing.title
    assert_select ".conversation-list-heading span", text: "Jun 7, 2026 8:18 PM CT"
    assert_select "details.conversation-actions"
    assert_select "form[action='#{conversation_path(conversation)}'][method='post'][data-turbo-confirm='Are you sure you want to delete this chat?'] button.conversation-delete-button", text: "Delete chat"
    assert_select "header.topbar nav.topbar-nav"
    assert_select ".chat-topbar", count: 0
    assert_select "a[href='#{root_path(anchor: 'recommendations')}'] svg.nav-item-icon"
    assert_select "a[href='#{search_results_path}'] svg.nav-item-icon"
    assert_select "a[href='#{saved_path}'] svg.nav-item-icon"
    assert_select "a[href='#{post_sublet_path}'] svg.nav-item-icon"
    assert_select "a[href='#{conversations_path}'] svg.nav-item-icon"
    assert_select "a[href='#{conversations_path}'][aria-current='page']", count: 0
    assert_select "a[href='#{profile_path}'] svg.nav-item-icon"
    assert_select "form[action='#{session_path}'] button", text: "Log out"
  end

  test "conversation thread message timestamps display in central time" do
    renter = sign_in_with_firebase_email("chat.timestamp@u.northwestern.edu")
    conversation = Conversation.between(renter, @host, listing: @listing)
    conversation.save!
    message = conversation.messages.create!(
      sender: renter,
      body: "Central time check.",
      created_at: Time.utc(2026, 6, 8, 1, 18, 0)
    )

    get conversation_path(conversation)

    assert_response :success
    assert_select "time[datetime='#{message.created_at.iso8601}']", text: "Jun 7, 2026 8:18 PM CT"
    assert_select "form[action='#{conversation_message_path(conversation, message)}'][method='post'][data-turbo-confirm='Are you sure you want to delete this message?'] button.message-delete-button"
    assert_select "header.topbar nav.topbar-nav"
    assert_select ".chat-topbar", count: 0
    assert_select "a[href='#{conversations_path}'] svg.nav-item-icon"
    assert_select "a[href='#{conversations_path}'][aria-current='page']", count: 0
  end

  test "conversation thread hides existing blank messages" do
    renter = sign_in_with_firebase_email("chat.blank.viewer@u.northwestern.edu")
    conversation = Conversation.between(renter, @host, listing: @listing)
    conversation.save!
    blank_message = conversation.messages.create!(sender: @host, body: "Temporary blank")
    blank_message.update_column(:body, "   ")
    visible_message = conversation.messages.create!(sender: @host, body: "Visible message")

    get conversation_path(conversation)

    assert_response :success
    assert_select ".message-bubble", count: 1
    assert_select ".message-bubble[data-message-id='#{visible_message.id}']"
    assert_select ".message-bubble[data-message-id='#{blank_message.id}']", count: 0
    assert_select ".message-body", text: "Visible message"
  end

  test "blank and whitespace only messages are rejected" do
    renter = sign_in_with_firebase_email("chat.blank.sender@u.northwestern.edu")
    conversation = Conversation.between(renter, @host, listing: @listing)
    conversation.save!

    assert_no_difference("Message.count") do
      post conversation_messages_path(conversation),
           params: { message: { body: "   " } },
           headers: { "Accept" => "application/json" }
    end

    assert_response :unprocessable_entity
    assert_includes response.parsed_body["errors"], "Body can't be blank"
  end

  test "participant can delete a conversation and its messages" do
    renter = sign_in_with_firebase_email("chat.delete.conversation@u.northwestern.edu")
    conversation = Conversation.between(renter, @host, listing: @listing)
    conversation.save!
    conversation.messages.create!(sender: renter, body: "Please delete this chat.")

    assert_difference("Conversation.count", -1) do
      assert_difference("Message.count", -1) do
        delete conversation_path(conversation)
      end
    end

    assert_redirected_to conversations_path
    follow_redirect!
    assert_response :success
    assert_select "a[href='#{conversation_path(conversation)}']", count: 0
  end

  test "logged out users cannot delete conversations" do
    renter = User.create!(name: "Logged Out Renter", email: "logged.out.chat@u.northwestern.edu", active: true, confirmed_at: Time.current)
    conversation = Conversation.between(renter, @host, listing: @listing)
    conversation.save!

    assert_no_difference("Conversation.count") do
      delete conversation_path(conversation)
    end

    assert_redirected_to login_path
  end

  test "non participants cannot delete conversations" do
    renter = sign_in_with_firebase_email("chat.delete.owner@u.northwestern.edu")
    conversation = Conversation.between(renter, @host, listing: @listing)
    conversation.save!
    sign_in_with_firebase_email("chat.delete.outsider@u.northwestern.edu")

    assert_no_difference("Conversation.count") do
      delete conversation_path(conversation)
    end

    assert_response :not_found
  end

  test "sender can delete their own message" do
    renter = sign_in_with_firebase_email("chat.delete.message@u.northwestern.edu")
    conversation = Conversation.between(renter, @host, listing: @listing)
    conversation.save!
    message = conversation.messages.create!(sender: renter, body: "Delete this message.")

    assert_difference("Message.count", -1) do
      delete conversation_message_path(conversation, message)
    end

    assert_redirected_to conversation_path(conversation)
    follow_redirect!
    assert_response :success
    assert_select ".message-bubble[data-message-id='#{message.id}']", count: 0
  end

  test "users cannot delete messages sent by someone else" do
    renter = sign_in_with_firebase_email("chat.delete.other.viewer@u.northwestern.edu")
    conversation = Conversation.between(renter, @host, listing: @listing)
    conversation.save!
    message = conversation.messages.create!(sender: @host, body: "Host message.")

    assert_no_difference("Message.count") do
      delete conversation_message_path(conversation, message)
    end

    assert_redirected_to conversation_path(conversation)
    follow_redirect!
    assert_response :success
    assert_select ".message-bubble[data-message-id='#{message.id}']"
    assert_select "form[action='#{conversation_message_path(conversation, message)}']", count: 0
  end

  test "logged out users cannot delete messages" do
    renter = User.create!(name: "Logged Out Message Renter", email: "logged.out.message@u.northwestern.edu", active: true, confirmed_at: Time.current)
    conversation = Conversation.between(renter, @host, listing: @listing)
    conversation.save!
    message = conversation.messages.create!(sender: renter, body: "Still here.")

    assert_no_difference("Message.count") do
      delete conversation_message_path(conversation, message)
    end

    assert_redirected_to login_path
  end

  test "chat javascript blocks whitespace only messages and blank live bubbles" do
    javascript = Rails.root.join("app/javascript/application.js").read

    assert_includes javascript, 'const body = String(message.body || "").trim()'
    assert_includes javascript, "if (!messageList || !chatPage || !body"
    assert_includes javascript, 'input?.setCustomValidity("Message can\'t be blank.")'
    assert_includes javascript, "input?.reportValidity()"
  end

  test "signed in user can start a chat with an existing account holder" do
    sign_in_with_firebase_email("chat.verified.sender@u.northwestern.edu")
    student = User.create!(
      name: "Existing Student",
      email: "chat.existing.recipient@u.northwestern.edu",
      active: true
    )

    assert_difference("Conversation.count", 1) do
      post conversations_path, params: { recipient_id: student.id }
    end

    assert_redirected_to conversation_path(Conversation.order(:created_at).last)
  end

  test "only participants can view and post messages" do
    renter = sign_in_with_firebase_email("chat.participant@u.northwestern.edu")
    conversation = Conversation.between(renter, @host, listing: @listing)
    conversation.save!

    get conversation_path(conversation)
    assert_response :success

    assert_difference("Message.count", 1) do
      post conversation_messages_path(conversation), params: { message: { body: "Is this still available?" } }
    end

    sign_in_with_firebase_email("chat.outsider@u.northwestern.edu")

    get conversation_path(conversation)
    assert_response :not_found

    assert_no_difference("Message.count") do
      post conversation_messages_path(conversation), params: { message: { body: "I should not post." } }
    end
    assert_response :not_found
  end

  test "server-side message validation blocks profanity" do
    renter = sign_in_with_firebase_email("chat.profanity@u.northwestern.edu")
    conversation = Conversation.between(renter, @host, listing: @listing)
    conversation.save!

    assert_no_difference("Message.count") do
      post conversation_messages_path(conversation),
           params: { message: { body: "This message is shit." } },
           headers: { "Accept" => "application/json" }
    end

    assert_response :unprocessable_entity
    assert_includes response.parsed_body["errors"], ProfanityFilter::ERROR_MESSAGE
  end

  test "contact details are hidden by default and visible when enabled" do
    sign_in_with_firebase_email("chat.viewer@u.northwestern.edu")

    get user_profile_path(@host)
    assert_response :success
    assert_includes response.body, "Hidden by profile setting"
    assert_not_includes response.body, @host.email
    assert_not_includes response.body, @host.phone_number

    @host.update!(show_email_to_students: true, show_phone_to_students: true)

    get user_profile_path(@host)
    assert_response :success
    assert_includes response.body, @host.email
    assert_includes response.body, @host.phone_number
  end

  private

  def valid_listing_attributes
    {
      title: "Chat Ready Listing",
      description: "Clean furnished room within walking distance of campus.",
      price: 850,
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

  def sign_in_with_firebase_email(email)
    verifier = Class.new do
      define_method(:verify) do |_id_token|
        {
          "email" => email,
          "email_verified" => true,
          "name" => "Test Student"
        }
      end
    end.new

    original_new = FirebaseTokenVerifier.method(:new)
    FirebaseTokenVerifier.define_singleton_method(:new) { |*| verifier }

    post session_path, params: { id_token: "firebase-token" }, as: :json
    if response.media_type == "application/json" && response.parsed_body["requires_terms_acceptance"]
      post onboarding_accept_terms_path, params: { terms_accepted: "1" }
    end
    User.find_by!(email: email)
  ensure
    FirebaseTokenVerifier.define_singleton_method(:new) { |*args, **kwargs| original_new.call(*args, **kwargs) }
  end
end
