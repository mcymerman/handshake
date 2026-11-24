# A safety report with the least data that lets us act. Evidence (the last
# 20 messages) is attached only if the reporter chooses to. Reports are
# deleted after 90 days.
class Report < ApplicationRecord
  REASONS = {
    "harassment" => "Harassment or bullying",
    "threat" => "Threats or feeling unsafe",
    "scam" => "Scam or spam",
    "underage" => "May be under 18",
    "other" => "Something else"
  }.freeze
  RETENTION = 90.days
  EVIDENCE_MESSAGES = 20

  encrypts :note, :evidence

  belongs_to :reporter_participant, class_name: "Participant", optional: true
  belongs_to :reported_participant, class_name: "Participant", optional: true

  validates :reason, inclusion: { in: REASONS.keys }
  validates :note, length: { maximum: 1_000 }
  validates :status, inclusion: { in: %w[open resolved] }

  scope :open, -> { where(status: "open") }
  scope :stale, -> { where(arel_table[:created_at].lt(RETENTION.ago)) }

  def self.file!(reporter:, reported:, reason:, note:, include_evidence:)
    evidence = (build_evidence(reporter) if include_evidence)
    create!(chat_thread_id: reporter.chat_thread_id, reporter_participant_id: reporter.participant_id,
            reported_participant_id: reported&.participant_id, reported_alias: reported&.alias_name,
            reason:, note: note.presence, evidence:).tap { Metric.bump(:reports) }
  end

  def self.build_evidence(reporter)
    reporter.visible_messages.where(kind: "text").reorder(seq: :desc).limit(EVIDENCE_MESSAGES).to_a.reverse.map do |m|
      "#{m.created_at.strftime('%b %-d %H:%M')} #{m.author_alias}: #{m.body}"
    end.join("\n")
  end

  def reason_label = REASONS.fetch(reason, reason)

  def resolve! = update!(status: "resolved", resolved_at: Time.current)
end
