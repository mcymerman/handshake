# A request to add or remove someone. Existing members are asked and the
# chat's approval policy decides. Nobody is ever added silently, and how
# each person voted is never shown.
class MembershipProposal < ApplicationRecord
  TIMEOUT = 10.minutes
  KINDS = %w[add remove].freeze
  VIAS = %w[add_in group_handshake member demo].freeze
  STATUSES = %w[pending approved rejected expired cancelled].freeze

  belongs_to :chat_thread
  belongs_to :subject_participant, class_name: "Participant"
  belongs_to :proposer_membership, class_name: "Membership", optional: true
  has_many :proposal_votes, dependent: :delete_all

  validates :kind, inclusion: { in: KINDS }
  validates :via, inclusion: { in: VIAS }
  validates :status, inclusion: { in: STATUSES }

  scope :pending, -> { where(status: "pending") }
  scope :overdue, -> { pending.where(arel_table[:expires_at].lteq(Time.current)) }

  before_validation { self.expires_at ||= TIMEOUT.from_now }

  def self.propose_add!(thread:, newcomer:, proposer:, via:)
    thread.with_lock do
      return :already_member if thread.member?(newcomer)
      return :already_pending if thread.pending_adds.exists?(subject_participant: newcomer)
      return :busy if via == "add_in" && proposer && thread.pending_adds.exists?(proposer_membership: proposer, via: "add_in")
      return :full if thread.open_seats <= 0

      proposal = create!(chat_thread: thread, kind: "add", subject_participant: newcomer,
                         proposer_membership: proposer, via:)
      thread.post_system!("#{proposer&.alias_name || 'Someone'} wants to add someone new. #{proposal.policy_hint}")
      Broadcasts.proposals_changed(thread)
      proposal
    end.tap { |result| result.evaluate! if result.is_a?(self) }
  end

  def self.propose_removal!(thread:, target:, proposer:)
    return :not_member unless target.chat_thread_id == thread.id && proposer.chat_thread_id == thread.id
    return :self if target == proposer
    return :already_pending if thread.pending_proposals.exists?(kind: "remove", subject_participant_id: target.participant_id)

    proposal = create!(chat_thread: thread, kind: "remove", subject_participant_id: target.participant_id,
                       proposer_membership: proposer, via: "member", expires_at: 1.day.from_now)
    thread.post_system!("#{proposer.alias_name} asked to remove #{target.alias_name}. #{proposal.policy_hint}")
    Broadcasts.proposals_changed(thread)
    proposal.evaluate!
    proposal
  end

  def pending? = status == "pending"
  def add? = kind == "add"
  def subject_membership = chat_thread.memberships.find_by(participant_id: subject_participant_id)
  def subject_alias = add? ? "the newcomer" : subject_membership&.alias_name || "someone"

  # The sponsor of an add-in vouched for the newcomer face to face (they
  # typed each other's codes), so their yes is implicit. A group handshake
  # can be entered by anyone nearby, so its opener votes like everyone else.
  def implicit_yes? = proposer_membership_id.present? && via != "group_handshake"

  # People whose answer counts: every member except an implicit-yes proposer
  # and the person being removed.
  def voters
    scope = chat_thread.memberships.where.not(participant_id: subject_participant_id)
    implicit_yes? ? scope.where.not(id: proposer_membership_id) : scope
  end

  def awaiting?(membership)
    pending? && voters.exists?(membership.id) && !proposal_votes.exists?(membership:)
  end

  def vote!(membership, decision)
    return false unless %w[approve decline].include?(decision) && awaiting?(membership)

    proposal_votes.create!(membership:, decision:)
    evaluate!
    true
  end

  def policy_hint
    case chat_thread.approval_policy
    when "unanimous" then "Everyone here needs to say yes."
    when "majority" then "Most people here need to say yes."
    else "One yes is enough."
    end
  end

  # Applies the policy. Safe to call repeatedly.
  def evaluate!
    with_lock do
      return status unless pending?
      return expire! if expires_at.past?

      voter_ids = voters.pluck(:id)
      votes = proposal_votes.where(membership_id: voter_ids)
      implicit = implicit_yes? ? 1 : 0
      yes = votes.where(decision: "approve").count + implicit
      no = votes.where(decision: "decline").count
      total = voter_ids.size + implicit

      case chat_thread.approval_policy
      when "unanimous"
        return finish!("rejected") if no.positive?
        return finish!("approved") if yes >= total
      when "majority"
        return finish!("approved") if yes * 2 > total
        return finish!("rejected") if no * 2 >= total
      when "any"
        return finish!("approved") if yes >= 1
        return finish!("rejected") if no >= total
      end
      status
    end
  end

  def expire! = finish!("expired")
  def cancel! = finish!("cancelled")

  private

  def finish!(new_status)
    update!(status: new_status, decided_at: Time.current)
    case [ kind, new_status ]
    when %w[add approved] then admit!
    when %w[remove approved] then remove!
    when %w[add rejected] then turn_away!("The group didn't add anyone this time.", "Not this time. The group decided to keep this chat as it is.")
    when %w[add expired] then turn_away!("The request to add someone timed out.", "Nobody answered in time, so you weren't added.")
    when %w[remove rejected], %w[remove expired]
      chat_thread.post_system!("The request to remove #{subject_alias} didn't pass.")
    end
    Broadcasts.proposals_changed(chat_thread)
    new_status
  end

  def admit!
    membership = chat_thread.add_member!(subject_participant)
    Broadcasts.visit(subject_participant, Rails.application.routes.url_helpers.chat_thread_path(chat_thread))
    membership
  rescue ActiveRecord::RecordInvalid
    update!(status: "rejected")
    turn_away!("The chat was full.", "The chat is full, so you weren't added.")
  end

  def remove!
    membership = subject_membership
    return unless membership

    if chat_thread.memberships.count <= 2
      chat_thread.vanish!(reason: "This chat has ended.")
    else
      alias_name = membership.alias_name
      membership.destroy!
      chat_thread.post_system!("#{alias_name} was removed by the group.")
      Broadcasts.chat_ended(subject_participant_id, chat_thread_id, "The group removed you from this chat.")
      Broadcasts.disconnect_from_thread(subject_participant)
    end
  end

  def turn_away!(thread_note, newcomer_note)
    chat_thread.post_system!(thread_note)
    Broadcasts.notice(subject_participant, newcomer_note)
    Broadcasts.visit(subject_participant, Rails.application.routes.url_helpers.root_path)
  end
end
