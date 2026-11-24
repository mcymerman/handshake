require "test_helper"

class LeaveAndDissolveTest < ActiveSupport::TestCase
  test "ending a one-to-one chat deletes it for both people" do
    alice = new_participant
    bob = new_participant
    thread = connect!(alice, bob)
    thread.post!(thread.membership_for(alice), "hello")

    thread.membership_for(bob).leave!

    refute ChatThread.exists?(thread.id)
    assert_equal 0, Message.where(chat_thread_id: thread.id).count
    assert_equal 0, Membership.where(chat_thread_id: thread.id).count
  end

  test "leaving a group keeps it going while 2 or more remain, then it dissolves" do
    alice = new_participant
    bob = new_participant
    thread = connect!(alice, bob)
    carol_m = thread.add_member!(new_participant)
    carol_m.chat_thread.post!(carol_m, "carol was here")

    carol_m.leave!
    assert ChatThread.exists?(thread.id)
    assert_equal 2, thread.memberships.count
    left_message = thread.messages.find_by(kind: "text")
    assert left_message.author_left?, "past messages stay, marked as left"

    thread.membership_for(alice).leave!
    refute ChatThread.exists?(thread.id), "fewer than 2 members: the chat dissolves"
  end

  test "extending needs everyone" do
    alice = new_participant
    bob = new_participant
    thread = connect!(alice, bob)
    before = thread.expires_at

    refute thread.request_extension!(thread.membership_for(alice))
    assert thread.request_extension!(thread.membership_for(bob))
    assert_in_delta (before + 14.days).to_i, thread.reload.expires_at.to_i, 2
  end

  test "deleting your device removes you from every chat" do
    alice = new_participant
    thread = connect!(alice, new_participant)
    alice.erase!
    refute ChatThread.exists?(thread.id)
    refute Participant.exists?(alice.id)
  end
end
