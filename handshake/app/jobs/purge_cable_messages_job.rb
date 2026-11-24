# Every minute: drop delivered broadcasts older than the retention window
# (10 minutes in production). They hold rendered message text, so they must
# not linger in quiet periods when Solid Cable's own trimming doesn't run.
class PurgeCableMessagesJob < ApplicationJob
  def perform
    return unless defined?(SolidCable::Message)

    SolidCable::Message.trimmable.in_batches(of: 1_000).delete_all
  end
end
