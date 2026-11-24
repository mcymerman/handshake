# The reveal ladder, one pair at a time. Each person chooses how far they're
# willing to go with one other person; a step shows only when both chose it.
#   0 chat only, 1 first name + photo, 2 social handles, 3 phone number
class RevealGrant < ApplicationRecord
  LEVELS = { 0 => "Chat only", 1 => "First name and photo", 2 => "Social handles", 3 => "Phone number" }.freeze

  belongs_to :chat_thread
  belongs_to :from_membership, class_name: "Membership"
  belongs_to :to_membership, class_name: "Membership"

  validates :level, inclusion: { in: LEVELS.keys }

  def self.offered(from, to) = find_by(from_membership: from, to_membership: to)&.level || 0

  def self.mutual_level(a, b) = [ offered(a, b), offered(b, a) ].min

  # Steps go in order: you can offer one step beyond what you both share,
  # and you can always step back down.
  def self.offer!(from:, to:, level:)
    level = Integer(level)
    raise ArgumentError, "not in the same chat" unless from.chat_thread_id == to.chat_thread_id && from != to
    raise ArgumentError, "unknown step" unless LEVELS.key?(level)
    raise ArgumentError, "one step at a time" if level > mutual_level(from, to) + 1

    before = mutual_level(from, to)
    grant = find_or_initialize_by(chat_thread_id: from.chat_thread_id, from_membership: from, to_membership: to)
    grant.update!(level:)
    after = mutual_level(from, to)
    Metric.bump(:"reveal_step_#{after}") if after > before
    grant
  end
end
