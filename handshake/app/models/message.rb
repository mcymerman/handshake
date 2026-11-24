# A chat message. Text is encrypted at rest and never logged. Messages are
# deleted with their chat.
class Message < ApplicationRecord
  MAX_LENGTH = 2_000

  encrypts :body

  belongs_to :chat_thread
  belongs_to :membership, optional: true

  validates :body, presence: true, length: { maximum: MAX_LENGTH }
  validates :kind, inclusion: { in: %w[text system] }

  def system? = kind == "system"
  def author_left? = !system? && membership_id.nil?

  def broadcast_to_thread
    Turbo::StreamsChannel.broadcast_append_to(chat_thread, target: "messages",
                                              partial: "messages/message", locals: { message: self })
  end
end
