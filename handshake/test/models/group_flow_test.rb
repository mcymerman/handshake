require "test_helper"

class GroupFlowTest < ActiveSupport::TestCase
  setup do
    @alice = new_participant
    @bob = new_participant
    @thread = connect!(@alice, @bob)
    @alice_m = @thread.membership_for(@alice)
    @bob_m = @thread.membership_for(@bob)
  end

  # Alice shows an add-in code; Carol enters it and Alice enters Carol's code.
  def add_in!(sponsor, newcomer, thread = @thread)
    _, thread_display = issue(sponsor, 47, kind: "add_in", chat_thread: thread)
    _, newcomer_display = issue(newcomer)
    assert_equal :waiting, enter(newcomer, thread_display).status
    result = enter(sponsor, newcomer_display)
    assert_equal :join_requested, result.status
    result.proposal
  end

  test "add-in code needs a mutual handshake, then unanimous approval" do
    carol = new_participant
    proposal = add_in!(@alice, carol)

    assert proposal.pending?
    refute @thread.member?(carol), "nobody is added silently"
    assert proposal.awaiting?(@bob_m)
    refute proposal.awaiting?(@alice_m), "the sponsor's yes is implicit"

    proposal.vote!(@bob_m, "approve")
    assert_equal "approved", proposal.reload.status
    assert @thread.member?(carol)
  end

  test "one add-in code alone does nothing" do
    carol = new_participant
    _, thread_display = issue(@alice, 47, kind: "add_in", chat_thread: @thread)
    issue(carol)

    assert_equal :waiting, enter(carol, thread_display).status
    assert_equal 0, @thread.membership_proposals.count
  end

  test "under unanimous approval one no rejects the newcomer" do
    carol = new_participant
    dave = new_participant
    @thread.add_member!(dave)
    proposal = add_in!(@alice, carol)

    proposal.vote!(@bob_m, "approve")
    assert proposal.reload.pending?, "still waiting for Dave"
    proposal.vote!(@thread.membership_for(dave), "decline")

    assert_equal "rejected", proposal.reload.status
    refute @thread.member?(carol)
  end

  test "join requests time out after 10 minutes" do
    proposal = add_in!(@alice, new_participant)

    travel 11.minutes
    ExpireProposalsJob.perform_now
    assert_equal "expired", proposal.reload.status
    refute @thread.member?(proposal.subject_participant)
  end

  test "majority and any-member policies" do
    @thread.update!(approval_policy: "majority")
    3.times { @thread.add_member!(new_participant) } # 5 members
    proposal = add_in!(@alice, new_participant)
    voters = proposal.voters.to_a
    proposal.vote!(voters[0], "approve")
    assert proposal.reload.pending?, "2 of 5 is not a majority"
    proposal.vote!(voters[1], "approve")
    assert_equal "approved", proposal.reload.status

    @thread.update!(approval_policy: "any")
    proposal = add_in!(@bob, new_participant)
    assert_equal "approved", proposal.reload.status, "the sponsor alone is enough"
    assert @thread.messages.where(kind: "system").where("created_at >= ?", proposal.created_at).exists?, "members are told"
  end

  test "loosening the policy needs everyone; tightening is instant" do
    assert_equal :proposed, @thread.change_policy!(@alice_m, "any")
    assert_equal "unanimous", @thread.reload.approval_policy
    assert_equal :applied, @thread.change_policy!(@bob_m, "any")
    assert_equal "any", @thread.reload.approval_policy
    assert_equal :applied, @thread.change_policy!(@alice_m, "unanimous")
  end

  test "group handshake: anyone nearby can ask to join, the group still approves" do
    _, group_display = issue(@alice, 47, kind: "group", chat_thread: @thread)
    carol = new_participant
    dave = new_participant

    assert_equal :join_requested, enter(carol, group_display).status
    assert_equal :join_requested, enter(dave, group_display).status, "the group code works for several people"
    refute @thread.member?(carol)
    carol_request, dave_request = @thread.pending_adds.order(:created_at).to_a
    carol_request.vote!(@bob_m, "approve")
    refute @thread.member?(carol), "the opener didn't vet strangers, so the opener votes too"
    carol_request.vote!(@alice_m, "approve")
    assert @thread.member?(carol)

    dave_request.vote!(@bob_m, "approve")
    dave_request.vote!(@alice_m, "approve")
    refute @thread.member?(dave), "Carol is a member now, so she is asked too"
    dave_request.vote!(@thread.membership_for(carol), "approve")
    assert @thread.member?(dave)
  end

  test "under any-member approval a group handshake still needs a real yes" do
    @thread.update!(approval_policy: "any")
    _, group_display = issue(@alice, 47, kind: "group", chat_thread: @thread)
    stranger = new_participant

    assert_equal :join_requested, enter(stranger, group_display).status
    refute @thread.member?(stranger), "nobody said yes yet"
    @thread.pending_adds.first.vote!(@bob_m, "approve")
    assert @thread.member?(stranger)
  end

  test "an unknown vote is ignored, not a crash" do
    proposal = add_in!(@alice, new_participant)
    refute proposal.vote!(@bob_m, "maybe")
    assert proposal.reload.pending?
  end

  test "the group cap is 8 including pending newcomers" do
    5.times { @thread.add_member!(new_participant) } # 7 members
    add_in!(@alice, new_participant)                  # 1 pending = 8
    _, group_display = issue(@bob, 47, kind: "group", chat_thread: @thread)

    assert_equal :thread_full, enter(new_participant, group_display).status
  end

  test "new members see only messages sent after they join" do
    @thread.post!(@alice_m, "before carol")
    travel 1.second
    carol_m = @thread.add_member!(new_participant)
    travel 1.second
    @thread.post!(@bob_m, "after carol")

    bodies = carol_m.visible_messages.where(kind: "text").map(&:body)
    assert_equal [ "after carol" ], bodies
  end

  test "removal needs the same approval as adding" do
    carol_m = @thread.add_member!(new_participant)
    proposal = MembershipProposal.propose_removal!(thread: @thread, target: carol_m, proposer: @alice_m)

    assert proposal.pending?
    refute proposal.voters.exists?(carol_m.id), "the person being removed doesn't vote"
    proposal.vote!(@bob_m, "approve")
    refute @thread.member?(carol_m.participant)
    assert @thread.reload.live?
  end
end
