# Every 10 minutes: chats past their expiry vanish with all their messages,
# memberships, reveals and requests. Queries already hide expired chats, so
# this is the cleanup, not the enforcement.
class PurgeExpiredThreadsJob < ApplicationJob
  def perform
    ChatThread.expired.find_each do |thread|
      thread.vanish!(reason: "A chat reached its 14 days and vanished.")
      Metric.bump(:chats_expired)
    end
  end
end
