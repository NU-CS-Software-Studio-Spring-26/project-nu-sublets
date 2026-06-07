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
  end

  test "conversation thread message timestamps display in central time" do
    renter = sign_in_with_firebase_email("chat.timestamp@u.northwestern.edu")
    conversation = Conversation.between(renter, @host, listing: @listing)
    conversation.save!
    message = conversation.messages.create!(
      sender: @host,
      body: "Central time check.",
      created_at: Time.utc(2026, 6, 8, 1, 18, 0)
    )

    get conversation_path(conversation)

    assert_response :success
    assert_select "time[datetime='#{message.created_at.iso8601}']", text: "Jun 7, 2026 8:18 PM CT"
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
