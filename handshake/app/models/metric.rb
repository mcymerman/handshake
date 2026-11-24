# Privacy-safe instrumentation: daily totals only. No user ids, no events,
# nothing that can be joined back to a person or a chat.
class Metric < ApplicationRecord
  self.table_name = "daily_metrics"

  KEYS = %w[handshakes handshakes_at_venues handshakes_in_areas chats_started groups_formed second_conversations back_and_forth reveal_step_1 reveal_step_2
            reveal_step_3 joins_via_add_in joins_via_group_handshake chats_ended chats_expired
            eavesdrop_alerts reports].freeze

  def self.bump(key, by: 1)
    key = key.to_s
    return unless KEYS.include?(key)

    row = find_or_create_by!(day: Date.current, key:)
    update_counters(row.id, count: by)
  rescue ActiveRecord::RecordNotUnique
    retry
  end

  def self.totals(since: 56.days.ago.to_date)
    where(day: since..).group(:key).sum(:count)
  end
end
