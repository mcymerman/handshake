# A cafe, gym, bar or event. Staff see counts only, never people.
class Venue < ApplicationRecord
  # Short, friendly words for the weekly two-word "table word".
  WORDS = %w[
    acorn bake bell bird boat bolt cake calm cove crab dawn deer dove drum
    echo fern fig fire fish flag fox frog gem glow goat gold harp hawk hill
    honey jade jazz kale kite lake lamp leaf lime lion lynx maple mint moon
    moss nest oak opal owl palm pear pine plum pond reed rice rose ruby
    sage sail seal snow star sun tea tide tulip wave wolf wren yarn zinc
  ].freeze

  has_many :zones, dependent: :destroy
  has_many :venue_daily_counts, dependent: :delete_all

  validates :name, presence: true, length: { maximum: 80 }

  before_validation :assign_secrets, on: :create

  # Returns [venue, raw_dashboard_token]; only the digest is stored.
  def self.create_with_dashboard_token!(**attrs)
    token = SecureRandom.urlsafe_base64(24)
    [ create!(dashboard_token_digest: Participant.digest_token(token), **attrs), token ]
  end

  def self.find_by_dashboard_token(token)
    return if token.blank?

    find_by(dashboard_token_digest: Participant.digest_token(token))
  end

  # The QR code and table word rotate every ISO week. Last week's values keep
  # working until Monday noon so a late reprint doesn't strand anyone.
  def qr_token(time = Time.current) = signature("qr", week_key(time))[0, 16]

  # Two words ("maple fox"): about 5,000 combinations, so it can't be
  # worked through from home within the rate limits.
  def table_word(time = Time.current)
    n = signature("word", week_key(time)).to_i(16)
    first = WORDS[n % WORDS.size]
    second = (WORDS - [ first ])[(n / WORDS.size) % (WORDS.size - 1)]
    "#{first} #{second}"
  end

  def valid_qr_token?(token, time = Time.current)
    accepted_times(time).any? { |t| ActiveSupport::SecurityUtils.secure_compare(qr_token(t), token.to_s) }
  end

  # Forgiving: "Maple Fox", "maple-fox" and "maplefox" all match.
  def valid_table_word?(word, time = Time.current)
    given = word.to_s.downcase.gsub(/[^a-z]/, "")
    given.present? && accepted_times(time).any? { |t| table_word(t).delete(" ") == given }
  end

  def week_range(time = Time.current)
    date = time.to_date
    date.beginning_of_week..date.end_of_week
  end

  def record!(metric)
    column = { connection: "connections", group: "groups" }.fetch(metric)
    count = venue_daily_counts.find_or_create_by!(day: Date.current)
    count.class.update_counters(count.id, column => 1)
  rescue ActiveRecord::RecordNotUnique
    retry
  end

  private

  def assign_secrets
    self.public_code ||= SecureRandom.alphanumeric(10).downcase
    self.tent_secret ||= SecureRandom.hex(32)
  end

  def week_key(time) = time.to_date.strftime("%G-W%V")
  def signature(purpose, key) = OpenSSL::HMAC.hexdigest("SHA256", tent_secret, "#{purpose}:#{key}")

  def accepted_times(time)
    monday_grace = time.monday? && time.hour < 12
    monday_grace ? [ time, time - 1.week ] : [ time ]
  end
end
