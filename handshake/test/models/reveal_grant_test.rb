require "test_helper"

class RevealGrantTest < ActiveSupport::TestCase
  setup do
    @alice = new_participant(first_name: "Alice", phone: "555 0100")
    @bob = new_participant(first_name: "Bob")
    @thread = connect!(@alice, @bob)
    @a = @thread.membership_for(@alice)
    @b = @thread.membership_for(@bob)
  end

  test "a step unlocks only when both choose it" do
    RevealGrant.offer!(from: @a, to: @b, level: 1)
    assert_equal 0, RevealGrant.mutual_level(@a, @b)

    RevealGrant.offer!(from: @b, to: @a, level: 1)
    assert_equal 1, RevealGrant.mutual_level(@a, @b)
    assert_equal 1, Metric.totals["reveal_step_1"]
  end

  test "steps go in order and can be withdrawn" do
    assert_raises(ArgumentError) { RevealGrant.offer!(from: @a, to: @b, level: 3) }
    RevealGrant.offer!(from: @a, to: @b, level: 1)
    RevealGrant.offer!(from: @b, to: @a, level: 1)
    RevealGrant.offer!(from: @a, to: @b, level: 2)
    RevealGrant.offer!(from: @b, to: @a, level: 2)
    assert_equal 2, RevealGrant.mutual_level(@a, @b)

    RevealGrant.offer!(from: @b, to: @a, level: 0)
    assert_equal 0, RevealGrant.mutual_level(@a, @b)
  end

  test "in a group, reveals stay between two people" do
    carol_m = @thread.add_member!(new_participant(first_name: "Carol"))
    RevealGrant.offer!(from: @a, to: @b, level: 1)
    RevealGrant.offer!(from: @b, to: @a, level: 1)

    assert_equal 1, RevealGrant.mutual_level(@a, @b)
    assert_equal 0, RevealGrant.mutual_level(@a, carol_m), "joining a group exposes nobody"
    assert_equal 0, RevealGrant.mutual_level(@b, carol_m)
  end

  test "back-and-forth is counted once, as a daily total, when two people each send 3 messages" do
    3.times { @thread.post!(@a, "hi") }
    2.times { @thread.post!(@b, "hey") }
    assert_nil Metric.totals["back_and_forth"]
    @thread.post!(@b, "third")
    @thread.post!(@b, "fourth")
    assert_equal 1, Metric.totals["back_and_forth"]
  end

  test "reveal details are encrypted at rest" do
    raw = Participant.connection.select_value("SELECT phone FROM participants WHERE id = #{Participant.connection.quote(@alice.id)}")
    refute_includes raw, "555 0100"
  end
end
