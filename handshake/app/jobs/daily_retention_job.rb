# Daily: reports after 90 days, idle devices after 30 days, and demo bots
# no longer in any chat.
class DailyRetentionJob < ApplicationJob
  IDLE_DEVICE = 30.days

  def perform
    Report.stale.delete_all
    Participant.where(last_seen_on: ...IDLE_DEVICE.ago.to_date).or(Participant.where(last_seen_on: nil, created_at: ...IDLE_DEVICE.ago))
               .where.not(plan: "demo").find_each(&:erase!)
    Participant.where(plan: "demo").where.missing(:memberships).where(created_at: ...1.hour.ago).find_each(&:destroy!)
    VenueDailyCount.where(day: ...13.months.ago.to_date).delete_all
  end
end
