# An anonymous device. The browser holds a random token in a signed,
# httpOnly cookie; we keep only its SHA-256, so a database copy can't be used
# to impersonate anyone.
class Participant < ApplicationRecord
  PLANS = {
    "free" => { max_threads: 20 },
    "premium" => { max_threads: 100 },
    "demo" => { max_threads: 1_000 }
  }.freeze
  PHOTO_FORMAT = %r{\Adata:image/(jpeg|png|webp);base64,[A-Za-z0-9+/=]+\z}

  encrypts :first_name, :photo_data, :social_handles, :phone

  has_many :memberships, dependent: :destroy
  has_many :chat_threads, through: :memberships
  has_many :handshake_codes, dependent: :delete_all

  validates :token_digest, presence: true, uniqueness: true
  validates :plan, inclusion: { in: PLANS.keys }
  validates :first_name, length: { maximum: 40 }
  validates :social_handles, length: { maximum: 200 }
  validates :phone, length: { maximum: 30 }, format: { with: /\A[0-9+().\- ]*\z/, message: "can only use digits, spaces and + ( ) . -" }
  validates :photo_data, length: { maximum: 400_000 }, format: { with: PHOTO_FORMAT }, allow_blank: true

  def self.digest_token(token)
    OpenSSL::Digest::SHA256.hexdigest(token.to_s)
  end

  # Returns [participant, raw_token]. The raw token goes only into the cookie.
  def self.create_with_token!(**attrs)
    token = SecureRandom.urlsafe_base64(32)
    [ create!(token_digest: digest_token(token), **attrs), token ]
  end

  def self.find_by_token(token)
    return if token.blank?

    find_by(token_digest: digest_token(token))
  end

  def suspended? = suspended_at.present?
  def demo? = plan == "demo"
  def thread_limit = PLANS.fetch(plan)[:max_threads]

  def live_threads
    chat_threads.live
  end

  def at_thread_limit?
    live_threads.count >= thread_limit
  end

  def touch_seen!
    update_column(:last_seen_on, Date.current) unless last_seen_on == Date.current
  end

  # Extension point: an optional account (email or passkey) that keeps chats
  # across devices. Not part of the MVP; anonymous devices are the default.
  def upgrade!(**)
    raise NotImplementedError, "Optional accounts are not built yet. See README: Extension points."
  end

  # Removes the device from every chat and deletes it. Used by "Delete
  # everything about me" and by the daily idle-device purge.
  def erase!
    memberships.includes(:chat_thread).find_each(&:leave!)
    destroy!
  end

  def suspend!
    transaction do
      update!(suspended_at: Time.current)
      memberships.includes(:chat_thread).find_each(&:leave!)
      handshake_codes.delete_all
    end
  end
end
