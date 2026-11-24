# A short-lived three-pair code, e.g. 47-12-83.
#
# We store only an HMAC of "zone:digits", keyed with a server secret, so a
# database copy can't be turned back into codes. Rows are deleted within
# about two minutes of expiry or a match (PurgeExpiredCodesJob).
class HandshakeCode < ApplicationRecord
  KINDS = %w[personal add_in group].freeze
  LIFETIMES = { "personal" => 60.seconds, "add_in" => 60.seconds, "group" => 2.minutes }.freeze
  # Typing slack: a code is still accepted for a few seconds after the screen moves on.
  GRACE = 10.seconds
  # Used codes are kept briefly so a late eavesdropper can be detected.
  RETENTION = 1.minute

  belongs_to :participant
  belongs_to :chat_thread, optional: true
  has_many :code_claims, dependent: :delete_all

  validates :kind, inclusion: { in: KINDS }
  validates :zone_number, inclusion: { in: 10..99 }

  scope :live, -> { where(consumed_at: nil).where(arel_table[:expires_at].gt(GRACE.ago)) }
  scope :purgeable, lambda {
    where(arel_table[:expires_at].lt(RETENTION.ago)).or(where(arel_table[:consumed_at].lt(RETENTION.ago)))
  }

  def self.digest_for(zone_number, digits)
    OpenSSL::HMAC.hexdigest("SHA256", secret, "#{Integer(zone_number)}:#{digits}")
  end

  def self.secret
    @secret ||= Rails.application.key_generator.generate_key("handshake/code-digest", 32)
  end

  # "47-12-83", "47 12 83", "471283" all parse to [47, "1283"].
  def self.parse(input)
    digits = input.to_s.gsub(/\D/, "")
    return unless digits.length == 6

    [ digits[0, 2].to_i, digits[2, 4] ]
  end

  def self.lookup(zone_number, digits)
    find_by(zone_number:, digest: digest_for(zone_number, digits))
  end

  def self.format(zone_number, digits)
    "#{zone_number}-#{digits[0, 2]}-#{digits[2, 2]}"
  end

  # Issues a fresh code that is unique among codes in this zone.
  # Returns [code, "47-12-83"]. The plain digits are never stored.
  def self.issue!(participant:, zone_number:, kind: "personal", chat_thread: nil)
    20.times do
      digits = Kernel.format("%04d", SecureRandom.random_number(10_000))
      digest = digest_for(zone_number, digits)
      where(zone_number:, digest:).purgeable.delete_all
      next if exists?(zone_number:, digest:)

      code = create!(participant:, zone_number:, digest:, kind:, chat_thread:,
                     expires_at: LIFETIMES.fetch(kind).from_now)
      return [ code, format(zone_number, digits) ]
    rescue ActiveRecord::RecordNotUnique
      next
    end
    raise "Zone is full; split it" # ~2,000+ live codes; no zone number here: logs never hold zones
  end

  def live? = consumed_at.nil? && expires_at > GRACE.ago
  def consumed? = consumed_at.present?
  def seconds_left = [ (expires_at - Time.current).ceil, 0 ].max
  def multi_use? = kind == "group"
end
