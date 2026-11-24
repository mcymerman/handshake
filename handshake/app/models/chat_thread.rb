# A private chat. Starts one-to-one, can grow to a group of up to 8.
# It vanishes for everyone when it expires, when the last pair ends it, or
# when fewer than 2 members remain.
class ChatThread < ApplicationRecord
  LIFETIME = 14.days
  MAX_MEMBERS = 8
  POLICIES = %w[unanimous majority any].freeze
  # Strictest first; loosening needs every member to agree.
  POLICY_STRICTNESS = { "unanimous" => 3, "majority" => 2, "any" => 1 }.freeze
  POLICY_LABELS = { "unanimous" => "Everyone agrees", "majority" => "Most people agree", "any" => "Any one member" }.freeze

  has_many :memberships, -> { order(:joined_at) }, dependent: :delete_all, inverse_of: :chat_thread
  has_many :participants, through: :memberships
  has_many :messages, -> { order(:seq) }, dependent: :delete_all
  has_many :membership_proposals, dependent: :delete_all
  has_many :reveal_grants, dependent: :delete_all
  has_many :handshake_codes, dependent: :delete_all

  validates :approval_policy, inclusion: { in: POLICIES }
  validates :max_members, numericality: { in: 2..MAX_MEMBERS }

  scope :live, -> { where(arel_table[:expires_at].gt(Time.current)) }
  scope :expired, -> { where(arel_table[:expires_at].lteq(Time.current)) }

  before_validation { self.expires_at ||= LIFETIME.from_now }

  def self.start!(first, second)
    transaction do
      thread = create!
      thread.add_member!(first, announce: false)
      thread.add_member!(second, announce: false)
      thread.post_system!("You're connected. Only the two of you are here.")
      Metric.bump(:chats_started)
      thread
    end
  end

  def live? = expires_at.future?
  def group? = memberships.size > 2
  def membership_for(participant) = memberships.find_by(participant:)
  def member?(participant) = memberships.exists?(participant:)
  def pending_proposals = membership_proposals.pending
  def pending_adds = pending_proposals.where(kind: "add")
  def open_seats = max_members - memberships.count - pending_adds.count
  def days_left = [ ((expires_at - Time.current) / 1.day).ceil, 0 ].max

  def add_member!(participant, announce: true)
    with_lock do
      raise ActiveRecord::RecordInvalid, self if memberships.count >= max_members

      membership = memberships.create!(participant:, alias_name: Membership.unique_alias(self), joined_at: Time.current)
      post_system!("#{membership.alias_name} joined.") if announce
      note_group_formed!
      membership
    end
  end

  # Appends a message with the next sequence number, so everyone sees the
  # same order whatever order the network delivers it in.
  def post!(membership, body, kind: "text")
    message = with_lock do
      seq = last_seq + 1
      today = Date.current
      new_day = last_message_on != today && kind == "text"
      update_columns(last_seq: seq, last_message_on: (new_day ? today : last_message_on),
                     message_days: message_days + (new_day ? 1 : 0))
      Metric.bump(:second_conversations) if new_day && message_days == 2
      messages.create!(membership:, author_alias: membership&.alias_name || "Handshake", body:, seq:, kind:)
    end
    message.broadcast_to_thread
    note_back_and_forth! if kind == "text"
    message
  end

  def post_system!(text) = post!(nil, text, kind: "system")

  # Everyone's agreement is needed to extend; each tap is remembered for a day.
  def request_extension!(membership)
    with_lock do
      membership.update!(extend_requested_at: Time.current)
      agreed = memberships.where(extend_requested_at: 1.day.ago..).count
      return false unless agreed == memberships.count

      update!(expires_at: expires_at + LIFETIME)
      memberships.update_all(extend_requested_at: nil)
      post_system!("Everyone agreed: this chat now vanishes in #{days_left} days.")
      true
    end
  end

  # Stricter takes effect at once. Looser needs every member to pick it.
  def change_policy!(membership, policy)
    raise ArgumentError, "unknown policy" unless POLICIES.include?(policy)
    return :unchanged if policy == approval_policy

    with_lock do
      if POLICY_STRICTNESS[policy] > POLICY_STRICTNESS[approval_policy]
        apply_policy!(policy, "#{membership.alias_name} changed who must agree to add or remove someone: #{POLICY_LABELS[policy]}.")
        return :applied
      end

      membership.update!(policy_vote: policy)
      if memberships.where(policy_vote: policy).count == memberships.count
        apply_policy!(policy, "Everyone agreed to change who must agree to add or remove someone: #{POLICY_LABELS[policy]}.")
        :applied
      else
        post_system!("#{membership.alias_name} suggests: #{POLICY_LABELS[policy]}. Everyone needs to pick it in Chat settings.")
        :proposed
      end
    end
  end

  # Deletes the chat and everything in it, for everyone.
  # The person who ended it (except:) is redirected by their own request.
  def vanish!(reason: "This chat has ended.", except: nil)
    member_ids = memberships.pluck(:participant_id) - [ except ]
    stream = Turbo::StreamsChannel.send(:stream_name_from, self)
    destroy!
    SolidCable::Message.where(channel: stream).delete_all if defined?(SolidCable::Message)
    member_ids.each { |pid| Broadcasts.chat_ended(pid, id, reason) }
  end

  private

  def apply_policy!(policy, text)
    update!(approval_policy: policy)
    memberships.update_all(policy_vote: nil)
    post_system!(text)
  end

  # Counted once per chat: at least two people have each sent 3+ messages.
  def note_back_and_forth!
    return if engaged_at || last_seq < 6

    talkers = messages.unscope(:order).where(kind: "text").where.not(membership_id: nil).group(:membership_id).having("COUNT(*) >= 3").count.size
    return if talkers < 2

    update_column(:engaged_at, Time.current)
    Metric.bump(:back_and_forth)
  end

  def note_group_formed!
    return if became_group_at || memberships.count < 3

    update_column(:became_group_at, Time.current)
    Metric.bump(:groups_formed)
  end
end
