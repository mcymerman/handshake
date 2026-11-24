require "test_helper"

class ExpiryJobsTest < ActiveSupport::TestCase
  test "expired chats are purged with their messages, memberships and reveals" do
    alice = new_participant
    bob = new_participant
    thread = connect!(alice, bob)
    a = thread.membership_for(alice)
    b = thread.membership_for(bob)
    thread.post!(a, "secret pancake")
    RevealGrant.offer!(from: a, to: b, level: 1)

    travel 15.days
    refute alice.live_threads.exists?(thread.id), "expired chats are hidden at once, before any job runs"
    PurgeExpiredThreadsJob.perform_now

    refute ChatThread.exists?(thread.id)
    assert_equal 0, Message.where(chat_thread_id: thread.id).count
    assert_equal 0, Membership.where(chat_thread_id: thread.id).count
    assert_equal 0, RevealGrant.where(chat_thread_id: thread.id).count
  end

  test "ending a chat also clears its queued live deliveries; old deliveries are purged every minute" do
    thread = connect!(new_participant, new_participant)
    stream = Turbo::StreamsChannel.send(:stream_name_from, thread)
    SolidCable::Message.broadcast(stream, "<p>secret pancake</p>")
    SolidCable::Message.broadcast("other-stream", "<p>keep me</p>")

    thread.membership_for(thread.participants.first).leave!
    refute SolidCable::Message.where(channel: stream).exists?
    assert SolidCable::Message.where(channel: "other-stream").exists?

    SolidCable::Message.where(channel: "other-stream").update_all(created_at: 3.days.ago)
    PurgeCableMessagesJob.perform_now
    refute SolidCable::Message.exists?
  end

  test "message text is encrypted at rest" do
    thread = connect!(new_participant, new_participant)
    message = thread.post!(thread.memberships.first, "secret pancake")
    raw = Message.connection.select_value("SELECT body FROM messages WHERE id = #{Message.connection.quote(message.id)}")
    refute_includes raw, "pancake"
  end

  test "daily retention deletes old reports and idle devices" do
    alice = new_participant
    thread = connect!(alice, new_participant)
    Report.file!(reporter: thread.memberships.first, reported: thread.memberships.last, reason: "scam", note: nil, include_evidence: false)
    idle = new_participant
    idle.update_column(:last_seen_on, 31.days.ago.to_date)

    travel 91.days do
      alice.update_column(:last_seen_on, Date.current)
      DailyRetentionJob.perform_now
    end
    assert_equal 0, Report.count
    refute Participant.exists?(idle.id)
    assert Participant.exists?(alice.id)
  end
end
