require "test_helper"

class ZoneTest < ActiveSupport::TestCase
  test "overnight opening hours" do
    venue, = seed_venue(zone_number: 21, opens: 17 * 60, closes: 2 * 60)
    zone = venue.zones.first
    assert zone.open_now?(Time.zone.parse("2026-11-24 23:30"))
    assert zone.open_now?(Time.zone.parse("2026-11-25 01:59"))
    refute zone.open_now?(Time.zone.parse("2026-11-25 10:00"))
  end

  test "themed windows" do
    venue, = seed_venue(zone_number: 22)
    zone = venue.zones.first
    zone.update!(theme_label: "Thursday trivia", theme_wday: 4, theme_start_minute: 19 * 60, theme_end_minute: 22 * 60)
    assert_equal "Thursday trivia", zone.current_theme(Time.zone.parse("2026-11-26 20:00"))
    assert_nil zone.current_theme(Time.zone.parse("2026-11-25 20:00"))
  end

  test "table word and QR token rotate weekly, last week's works until Monday noon" do
    venue, = seed_venue
    tuesday = Time.zone.parse("2026-11-24 12:00")
    next_monday_morning = Time.zone.parse("2026-11-30 09:00")
    next_monday_evening = Time.zone.parse("2026-11-30 18:00")

    word = venue.table_word(tuesday)
    token = venue.qr_token(tuesday)
    refute_equal token, venue.qr_token(next_monday_evening)
    assert venue.valid_table_word?(word.upcase, tuesday)
    assert venue.valid_qr_token?(token, next_monday_morning)
    refute venue.valid_qr_token?(token, next_monday_evening)
  end

  test "area zones map a rounded cell to a zone and its neighbours" do
    zone, neighbours = AreaZone.for_cell("4071", "-7400")
    assert_includes AreaZone::RANGE, zone
    assert neighbours.all? { AreaZone::RANGE.cover?(it) }
    north = AreaZone.number_for(4072, -7400)
    assert(north == zone || neighbours.include?(north), "the cell next door is a neighbour")
    assert_nil AreaZone.for_cell("abc", "1")
  end

  test "venue counts show small numbers as fewer than 3" do
    assert_equal "0", VenueDailyCount.display(0)
    assert_equal "fewer than 3", VenueDailyCount.display(2)
    assert_equal "3", VenueDailyCount.display(3)
  end
end
