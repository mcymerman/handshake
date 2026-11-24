# What happens when someone types a code.
#
#   A types B's code   -> a pending claim ("waiting for them")
#   B types A's code   -> both claims exist: match. Codes are used up and a
#                         private chat opens (or, for an add-in code, a join
#                         request goes to the group).
#   typo / no such code -> nothing is burned; it counts toward the lockout
#   a second person types a code that already has a claim
#                       -> the code is cancelled, the owner is alerted and
#                          gets a fresh one
class CodeEntry
  Result = Data.define(:status, :thread, :proposal, :code) do
    def success? = %i[matched waiting join_requested].include?(status)
  end

  # Failures that look like guessing and count toward lockouts.
  COUNTED_FAILURES = %i[not_found already_used].freeze

  attr_reader :participant, :zone_context, :input

  def initialize(participant:, zone_context:, input:)
    @participant = participant
    @zone_context = zone_context
    @input = input
  end

  def call
    return result(:suspended) if participant.suspended?
    return result(:no_zone) unless zone_context

    zone_number, digits = HandshakeCode.parse(input)
    return result(:invalid_format) unless zone_number
    return result(:out_of_zone) unless zone_context.accepts?(zone_number)

    code = HandshakeCode.lookup(zone_number, digits)
    return result(:not_found) unless code
    return result(:own_code) if code.participant_id == participant.id
    return used_code(code) if code.consumed?
    return result(:expired) unless code.live?

    code.multi_use? ? join_via_group_handshake(code) : claim(code)
  end

  private

  def result(status, thread: nil, proposal: nil, code: nil) = Result.new(status:, thread:, proposal:, code:)

  def used_code(code)
    Broadcasts.notice(code.participant_id, "Someone else tried a code you'd already used. They weren't connected to anyone.", tone: "warn")
    Metric.bump(:eavesdrop_alerts)
    result(:already_used)
  end

  def claim(code)
    owner = code.participant
    outcome = ActiveRecord::Base.transaction do
      # Lock both people in a fixed order so two simultaneous entries can't miss each other.
      Participant.where(id: [ participant.id, owner.id ].sort).order(:id).lock.to_a
      code.reload
      next result(:expired) unless code.live?

      reciprocal = CodeClaim.joins(:handshake_code).merge(HandshakeCode.live)
                            .where(participant_id: owner.id, handshake_codes: { participant_id: participant.id })
                            .order(:created_at).last
      if reciprocal
        complete_match(their_code: code, my_code: reciprocal.handshake_code)
      elsif code.code_claims.where.not(participant_id: participant.id).exists?
        eavesdrop!(code)
      else
        CodeClaim.find_or_create_by!(handshake_code: code, participant:)
        result(:waiting, code:)
      end
    end
    after_commit_effects(outcome)
    outcome
  end

  def complete_match(their_code:, my_code:)
    other = their_code.participant
    extra_claimants = (their_code.code_claims.where.not(participant_id: participant.id).pluck(:participant_id) +
                       my_code.code_claims.where.not(participant_id: other.id).pluck(:participant_id)).uniq
    @alert_owners = []
    @alert_owners << other.id if their_code.code_claims.where.not(participant_id: participant.id).exists?
    @alert_owners << participant.id if my_code.code_claims.where.not(participant_id: other.id).exists?
    @stranded = extra_claimants - [ participant.id, other.id ]

    add_in = [ their_code, my_code ].find { it.kind == "add_in" }
    if add_in && [ their_code, my_code ].all? { it.kind == "add_in" }
      return result(:both_adding)
    end

    consume!(their_code, my_code)
    @counted_zone = their_code.zone_number
    if add_in
      newcomer = add_in.participant_id == participant.id ? other : participant
      thread = add_in.chat_thread
      proposer = thread&.membership_for(add_in.participant)
      return result(:thread_gone) unless thread&.live? && proposer
      return result(:at_limit) if newcomer.at_thread_limit?

      proposal = MembershipProposal.propose_add!(thread:, newcomer:, proposer:, via: "add_in")
      return result(proposal_failure(proposal)) unless proposal.is_a?(MembershipProposal)

      Metric.bump(:joins_via_add_in)
      @notify = [ [ newcomer, waiting_path(proposal) ], [ add_in.participant, thread_path(thread) ] ]
      result(:join_requested, thread:, proposal:)
    else
      return result(:at_limit) if participant.at_thread_limit? || other.at_thread_limit?

      thread = ChatThread.start!(other, participant)
      @notify = [ [ other, thread_path(thread) ], [ participant, thread_path(thread) ] ]
      result(:matched, thread:)
    end
  end

  def join_via_group_handshake(code)
    thread = code.chat_thread
    return result(:thread_gone) unless thread&.live?
    return result(:at_limit) if participant.at_thread_limit?

    proposer = thread.membership_for(code.participant)
    return result(:thread_gone) unless proposer

    proposal = MembershipProposal.propose_add!(thread:, newcomer: participant, proposer:, via: "group_handshake")
    return result(proposal_failure(proposal)) unless proposal.is_a?(MembershipProposal)

    Metric.bump(:joins_via_group_handshake)
    @counted_zone = code.zone_number
    @group_join = true
    after_commit_effects(nil)
    result(:join_requested, thread:, proposal:)
  end

  def proposal_failure(outcome)
    { already_member: :already_member, already_pending: :already_pending, busy: :busy, full: :thread_full }.fetch(outcome, :thread_full)
  end

  def consume!(*codes)
    now = Time.current
    codes.each do |c|
      c.update!(consumed_at: now)
      c.code_claims.delete_all
    end
  end

  def eavesdrop!(code)
    claimants = code.code_claims.pluck(:participant_id) + [ participant.id ]
    code.destroy!
    @eavesdropped = { owner: code.participant_id, claimants: claimants.uniq }
    result(:code_changed)
  end

  # Broadcasts happen after the transaction so nobody is sent to a chat
  # that might still roll back.
  def after_commit_effects(outcome)
    if @eavesdropped
      Broadcasts.notice(@eavesdropped[:owner], "Two people entered your code, so we made you a fresh one. Show it only to the person in front of you.", tone: "warn")
      Broadcasts.refresh_code(@eavesdropped[:owner])
      (@eavesdropped[:claimants] - [ participant.id ]).each do |pid|
        Broadcasts.notice(pid, "That code changed. Ask them for their new one.", tone: "warn")
      end
      Metric.bump(:eavesdrop_alerts)
    end
    Array(@alert_owners).each do |pid|
      Broadcasts.notice(pid, "Someone else also entered your code. They weren't connected.", tone: "warn")
    end
    Array(@stranded).each { |pid| Broadcasts.notice(pid, "That code was used by someone else. Ask for a new one.", tone: "warn") }
    Array(@notify).each do |person, path|
      Broadcasts.refresh_code(person)
      Broadcasts.visit(person, path)
    end
    record_counts(outcome) if outcome&.success? || @group_join
  end

  def record_counts(outcome)
    return unless @counted_zone
    return if outcome && outcome.status == :waiting

    Metric.bump(:handshakes)
    Metric.bump(Zone::VENUE_RANGE.cover?(@counted_zone) ? :handshakes_at_venues : :handshakes_in_areas)
    zone = Zone.find_by(zone_number: @counted_zone) if Zone::VENUE_RANGE.cover?(@counted_zone)
    joined = @group_join || outcome&.status == :join_requested
    zone&.venue&.record!(joined ? :group : :connection)
  end

  def thread_path(thread) = Rails.application.routes.url_helpers.chat_thread_path(thread)
  def waiting_path(proposal) = Rails.application.routes.url_helpers.waiting_proposal_path(proposal)
end
