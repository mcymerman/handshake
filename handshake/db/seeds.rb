# Pilot seed data: one cafe, one climbing gym, one bar, plus a conference.
# Safe to run more than once. In development the staff dashboard links are
# predictable (/dash/dev-bean etc.) for demos; elsewhere they're random and
# printed once.
SEED_VENUES = [
  { key: "bean", name: "Bean There Cafe", zone: 47, label: "Bean There Cafe", neighbors: [ 48 ], opens: 7 * 60, closes: 19 * 60 },
  { key: "summit", name: "Summit Climbing", zone: 48, label: "Summit Climbing", neighbors: [ 47 ], opens: 6 * 60, closes: 23 * 60 },
  { key: "lantern", name: "The Lantern", zone: 21, label: "The Lantern bar", neighbors: [], opens: 17 * 60, closes: 2 * 60,
    theme: [ "Thursday trivia night", 4, 19 * 60, 22 * 60 ] },
  { key: "conf", name: "Open Source Summit (demo event)", zone: 12, label: "Main hall", neighbors: [ 13 ], opens: nil, closes: nil },
  { key: "conf2", name: "Open Source Summit (hallway)", zone: 13, label: "Hallway", neighbors: [ 12 ], opens: nil, closes: nil }
].freeze

SEED_VENUES.each do |spec|
  next if Zone.exists?(zone_number: spec[:zone])

  token = Rails.env.production? ? SecureRandom.urlsafe_base64(24) : "dev-#{spec[:key]}"
  venue = Venue.create!(name: spec[:name], dashboard_token_digest: Participant.digest_token(token))
  theme_label, theme_wday, theme_start, theme_end = spec[:theme]
  venue.zones.create!(zone_number: spec[:zone], label: spec[:label], neighbor_numbers: spec[:neighbors],
                      opens_minute: spec[:opens], closes_minute: spec[:closes], theme_label:, theme_wday:,
                      theme_start_minute: theme_start, theme_end_minute: theme_end)
  puts "#{venue.name}: zone #{spec[:zone]}, word '#{venue.table_word}', staff link /dash/#{token}"
end
