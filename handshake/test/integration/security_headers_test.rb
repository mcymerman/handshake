require "test_helper"

class SecurityHeadersTest < ActionDispatch::IntegrationTest
  test "pages carry a strict content security policy" do
    get welcome_path
    csp = response.headers["content-security-policy"]
    assert_match "default-src 'self'", csp
    assert_match "object-src 'none'", csp
    assert_match "frame-ancestors 'none'", csp
    refute_match "unsafe-inline", csp
  end

  test "forms carry CSRF tokens and forged posts are refused" do
    ActionController::Base.allow_forgery_protection = true
    get welcome_path
    assert_select "input[name=authenticity_token]"
    post welcome_path, params: { adult: "1" }
    assert_response :unprocessable_content
    assert_equal 0, Participant.count
  ensure
    ActionController::Base.allow_forgery_protection = false
  end

  test "production forces SSL and secure cookies" do
    production = File.read(Rails.root.join("config/environments/production.rb"))
    assert_match(/config\.force_ssl = ENV\.fetch\("FORCE_SSL", "true"\) != "false"/, production)
    assert_match(/config\.assume_ssl = ENV\.fetch\("FORCE_SSL", "true"\) != "false"/, production)
  end

  test "venue staff pages need the secret link and show counts only" do
    venue, token = seed_venue(zone_number: 40)
    get venue_dashboard_path("wrong")
    assert_response :not_found

    venue.record!(:connection)
    get venue_dashboard_path(token)
    assert_response :success
    assert_match "fewer than 3", response.body
    get venue_tent_path(token)
    assert_select ".tent .zone-big", /40/
    assert_select ".tent svg"
  end

  test "admin can create a venue with opening hours and a themed window" do
    ENV["ADMIN_PASSWORD"] = "correct horse battery"
    auth = { "Authorization" => ActionController::HttpAuthentication::Basic.encode_credentials("admin", "correct horse battery") }
    post admin_venues_path, headers: auth, params: { venue: { name: "Quiz Pub", zone_number: 33, opens: "17:00", closes: "02:00",
                                                              theme_label: "Thursday trivia night", theme_wday: "4", theme_starts: "19:00", theme_ends: "22:00" } }
    assert_response :success
    assert_match "/dash/", response.body, "the staff link is shown once"
    zone = Zone.find_by(zone_number: 33)
    assert_equal [ 1020, 120, 4, 1140, 1320 ], [ zone.opens_minute, zone.closes_minute, zone.theme_wday, zone.theme_start_minute, zone.theme_end_minute ]
    assert_equal "Thursday trivia night", zone.current_theme(Time.zone.parse("2026-11-26 20:00"))
  ensure
    ENV.delete("ADMIN_PASSWORD")
  end

  test "admin is off without a strong password and locked behind basic auth with one" do
    get admin_reports_path
    assert_response :not_found

    ENV["ADMIN_PASSWORD"] = "correct horse battery"
    get admin_reports_path
    assert_response :unauthorized
    get admin_reports_path, headers: { "Authorization" => ActionController::HttpAuthentication::Basic.encode_credentials("admin", "correct horse battery") }
    assert_response :success
  ensure
    ENV.delete("ADMIN_PASSWORD")
  end
end
