# A venue or event zone (10-49). Area zones (50-99) are computed by AreaZone
# and never stored.
class Zone < ApplicationRecord
  VENUE_RANGE = (10..49)

  belongs_to :venue

  validates :zone_number, inclusion: { in: VENUE_RANGE }, uniqueness: true
  validates :label, presence: true, length: { maximum: 80 }
  validates :opens_minute, :closes_minute, :theme_start_minute, :theme_end_minute,
            numericality: { in: 0..1439 }, allow_nil: true
  validates :theme_wday, inclusion: { in: 0..6 }, allow_nil: true
  validate :neighbors_are_zone_numbers

  def open_now?(time = Time.current)
    return true if opens_minute.nil? || closes_minute.nil?

    within?(minute_of(time), opens_minute, closes_minute)
  end

  def current_theme(time = Time.current)
    return if theme_label.blank? || theme_start_minute.nil? || theme_end_minute.nil?
    return if theme_wday && theme_wday != time.wday

    theme_label if within?(minute_of(time), theme_start_minute, theme_end_minute)
  end

  def accepted_numbers
    ([ zone_number ] + neighbor_numbers).uniq
  end

  def hours_label
    return "Always open" if opens_minute.nil? || closes_minute.nil?

    "#{format_minute(opens_minute)}–#{format_minute(closes_minute)}"
  end

  def format_minute(minute)
    Time.current.beginning_of_day.advance(minutes: minute).strftime("%-l:%M %P")
  end

  private

  def minute_of(time) = (time.hour * 60) + time.min

  # Handles overnight windows (opens 17:00, closes 02:00).
  def within?(minute, start, finish)
    start <= finish ? minute.between?(start, finish - 1) : (minute >= start || minute < finish)
  end

  def neighbors_are_zone_numbers
    return if neighbor_numbers.all? { |n| n.is_a?(Integer) && n.between?(10, 99) }

    errors.add(:neighbor_numbers, "must be zone numbers from 10 to 99")
  end
end
