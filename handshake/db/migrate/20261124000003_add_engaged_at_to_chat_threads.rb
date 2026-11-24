# Marks the moment a chat first has 3+ messages from at least two people,
# so the Cynic's early-warning metric can be counted as a daily total.
class AddEngagedAtToChatThreads < ActiveRecord::Migration[8.1]
  def change
    add_column :chat_threads, :engaged_at, :datetime
  end
end
