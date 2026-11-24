require "test_helper"

class ConnectionTest < ActionCable::Connection::TestCase
  tests ApplicationCable::Connection

  test "rejects a socket without a device cookie" do
    assert_reject_connection { connect }
  end

  test "identifies the device from its signed cookie" do
    participant, token = Participant.create_with_token!(age_confirmed_at: Time.current)
    cookies.signed[:hs_device] = token
    connect
    assert_equal participant, connection.current_participant
  end
end

class ChatThreadChannelTest < ActionCable::Channel::TestCase
  tests ChatThreadChannel

  setup do
    @alice = new_participant
    @bob = new_participant
    @thread = connect!(@alice, @bob)
    @signed = Turbo::StreamsChannel.signed_stream_name(@thread)
  end

  test "members can listen" do
    stub_connection current_participant: @alice
    subscribe signed_stream_name: @signed
    assert subscription.confirmed?
    assert_has_stream @thread.to_gid_param
  end

  test "non-members are refused even with a valid signed stream name" do
    stub_connection current_participant: new_participant
    subscribe signed_stream_name: @signed
    assert subscription.rejected?
  end

  test "a removed member is refused on reconnect" do
    carol = new_participant
    @thread.add_member!(carol)
    @thread.membership_for(carol).leave!
    stub_connection current_participant: carol
    subscribe signed_stream_name: @signed
    assert subscription.rejected?
  end

  test "forged stream names are refused" do
    stub_connection current_participant: @alice
    subscribe signed_stream_name: "forged--signature"
    assert subscription.rejected?
  end

  test "messages are broadcast to the chat in order" do
    membership = @thread.membership_for(@alice)
    assert_broadcasts(@thread.to_gid_param, 2) do
      @thread.post!(membership, "one")
      @thread.post!(membership, "two")
    end
    assert_equal [ "one", "two" ], @thread.messages.where(kind: "text").map(&:body)
    assert_equal @thread.messages.map(&:seq), @thread.messages.map(&:seq).sort
  end
end

class TurboStreamsChannelLockdownTest < ActionCable::Channel::TestCase
  tests Turbo::StreamsChannel

  test "Turbo's own channel refuses everyone, so membership checks can't be bypassed" do
    alice = new_participant
    thread = connect!(alice, new_participant)
    stub_connection current_participant: alice
    subscribe signed_stream_name: Turbo::StreamsChannel.signed_stream_name(thread)
    assert subscription.rejected?
  end
end

class ParticipantChannelTest < ActionCable::Channel::TestCase
  tests ParticipantChannel

  test "only the device itself can listen to its stream" do
    alice = new_participant
    signed = Turbo::StreamsChannel.signed_stream_name(Broadcasts.participant_stream(alice))

    stub_connection current_participant: new_participant
    subscribe signed_stream_name: signed
    assert subscription.rejected?

    stub_connection current_participant: alice
    subscribe signed_stream_name: signed
    assert subscription.confirmed?
  end
end
