# A person's seat in one chat, with a random alias used only in that chat
# so nobody can be linked across chats.
class Membership < ApplicationRecord
  ADJECTIVES = %w[Amber Brave Calm Clever Coral Cosmic Daring Gentle Golden Happy
                  Jolly Kind Lucky Mellow Misty Noble Plum Quiet Rosy Sunny Swift Teal Witty Zesty].freeze
  ANIMALS = %w[Badger Bear Crane Dolphin Falcon Finch Fox Gecko Heron Koala Lark Lemur
               Lynx Moose Otter Owl Panda Puffin Quail Raven Robin Seal Tiger Wren].freeze

  belongs_to :chat_thread
  belongs_to :participant
  has_many :messages, dependent: :nullify

  validates :alias_name, presence: true

  def self.unique_alias(thread)
    taken = thread.memberships.pluck(:alias_name)
    20.times do
      name = "#{ADJECTIVES.sample} #{ANIMALS.sample}"
      return name unless taken.include?(name)
    end
    "#{ADJECTIVES.sample} #{ANIMALS.sample} #{SecureRandom.random_number(90) + 10}"
  end

  def others = chat_thread.memberships.where.not(id:)

  # Messages sent from the moment this person joined.
  def visible_messages
    chat_thread.messages.where(created_at: joined_at..)
  end

  # Leaving a chat with 2 people ends it for both. In a group, the leaver's
  # seat goes and the chat carries on while at least 2 remain.
  def leave!
    thread = chat_thread
    vanished = false
    thread.with_lock do
      # Counted under the lock, so two people leaving at once can't strand a third.
      if thread.memberships.count <= 2
        vanished = true
      else
        thread.membership_proposals.pending.where(subject_participant_id: participant_id).find_each(&:cancel!)
        destroy!
        thread.post_system!("#{alias_name} left.")
      end
    end
    return thread.vanish!(reason: "This chat has ended.", except: participant_id) if vanished

    Broadcasts.disconnect_from_thread(participant)
    thread.membership_proposals.pending.find_each(&:evaluate!)
    thread
  end
end
