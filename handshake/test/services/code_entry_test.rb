require "test_helper"

class CodeEntryTest < ActiveSupport::TestCase
  setup do
    @alice = new_participant
    @bob = new_participant
  end

  test "mutual entry opens a private one-to-one chat" do
    thread = connect!(@alice, @bob)

    assert_equal [ @alice, @bob ].map(&:id).sort, thread.participants.map(&:id).sort
    assert_equal ChatThread::LIFETIME.from_now.to_date, thread.expires_at.to_date
  end

  test "one-sided entry never starts a chat" do
    _, bob_display = issue(@bob)
    issue(@alice)

    assert_no_difference -> { ChatThread.count } do
      assert_equal :waiting, enter(@alice, bob_display).status
    end
  end

  test "mutual entry must happen inside the window" do
    _, alice_display = issue(@alice)
    _, bob_display = issue(@bob)
    enter(@alice, bob_display)

    travel 75.seconds
    assert_equal :expired, enter(@bob, alice_display).status
    assert_equal 0, ChatThread.count
  end

  test "a code is single-use: it is consumed by a match" do
    _, alice_display = issue(@alice)
    _, bob_display = issue(@bob)
    enter(@alice, bob_display)
    enter(@bob, alice_display)

    carol = new_participant
    issue(carol)
    assert_equal :already_used, enter(carol, alice_display).status
    assert_equal 1, ChatThread.count
  end

  test "a typo does not burn the code" do
    _, alice_display = issue(@alice)
    _, bob_display = issue(@bob)

    assert_equal :not_found, enter(@alice, unused_display).status
    assert_equal :waiting, enter(@alice, bob_display).status
    assert_equal :matched, enter(@bob, alice_display).status
  end

  test "an eavesdropper who types an overheard code is not connected, and the owner gets a fresh code and an alert" do
    eve = new_participant
    alice_code, alice_display = issue(@alice)
    issue(eve)
    issue(@bob)

    assert_equal :waiting, enter(eve, alice_display).status
    assert_broadcasts(Broadcasts.participant_stream(@alice).join(":"), 2) do
      assert_equal :code_changed, enter(@bob, alice_display).status
    end
    refute HandshakeCode.exists?(alice_code.id), "the overheard code is cancelled"
    assert_equal 0, ChatThread.count
  end

  test "the real partner still connects when an eavesdropper typed the code first, and nobody else joins" do
    eve = new_participant
    _, alice_display = issue(@alice)
    _, bob_display = issue(@bob)
    issue(eve)

    enter(eve, alice_display)
    enter(@alice, bob_display)
    result = enter(@bob, alice_display)

    assert_equal :matched, result.status
    refute result.thread.member?(eve)
  end

  test "neighbouring zones are accepted, distant ones are not" do
    _, bob48 = issue(@bob, 48)
    _, carol21 = issue(new_participant, 21)
    issue(@alice, 47)

    assert_equal :waiting, enter(@alice, bob48, zone_ctx(47, neighbors: [ 48 ])).status
    assert_equal :out_of_zone, enter(@alice, carol21, zone_ctx(47, neighbors: [ 48 ])).status
  end

  test "people either side of a boundary connect" do
    _, alice47 = issue(@alice, 47)
    _, bob48 = issue(@bob, 48)

    enter(@alice, bob48, zone_ctx(47, neighbors: [ 48 ]))
    assert_equal :matched, enter(@bob, alice47, zone_ctx(48, neighbors: [ 47 ])).status
  end

  test "you can't connect to yourself" do
    _, mine = issue(@alice)
    assert_equal :own_code, enter(@alice, mine).status
  end

  test "suspended devices can't connect" do
    _, bob_display = issue(@bob)
    @alice.update!(suspended_at: Time.current)
    assert_equal :suspended, enter(@alice, bob_display).status
  end

  test "a successful match counts toward venue and daily totals" do
    venue, = seed_venue(zone_number: 47)
    connect!(@alice, @bob, 47)

    assert_equal 1, venue.venue_daily_counts.sum(:connections)
    assert_equal 1, Metric.totals["handshakes"]
    assert_equal 1, Metric.totals["handshakes_at_venues"]
  end
end
