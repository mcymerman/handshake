require "test_helper"

class OnboardingAndZoneTest < ActionDispatch::IntegrationTest
  setup { @venue, @token = seed_venue(zone_number: 47) }

  test "the health check answers" do
    get "/up"
    assert_response :success
  end

  test "first visit asks for the age gate before anything else" do
    get root_path
    assert_redirected_to welcome_path

    post welcome_path, params: { adult: "0" }
    assert_response :unprocessable_content
    assert_equal 0, Participant.count

    sign_in_new_device
    assert cookies[:hs_device].present?
    refute_includes response.headers["set-cookie"].to_s.downcase.scan(/hs_device[^,]*/).join, "samesite=none"
  end

  test "the device cookie is httpOnly and only a digest is stored" do
    post welcome_path, params: { adult: "1" }
    header = Array(response.headers["set-cookie"]).join("\n")
    assert_match(/hs_device=.*httponly/i, header)
    raw = cookies[:hs_device]
    refute Participant.exists?(token_digest: raw)
  end

  test "a venue zone needs this week's table word" do
    sign_in_new_device
    post zone_path, params: { zone_number: 47, word: "wrong" }
    assert_response :unprocessable_content

    choose_zone(@venue)
    get root_path
    assert_select ".code .zz", "47"
  end

  test "scanning the table tent QR sets the zone; an old token doesn't" do
    sign_in_new_device
    get scan_zone_path(public_code: @venue.public_code, token: "stale-token-123")
    assert_redirected_to new_zone_path

    get scan_zone_path(public_code: @venue.public_code, token: @venue.qr_token)
    assert_redirected_to root_path
  end

  test "a venue zone is closed outside its opening hours" do
    @venue.zones.first.update!(opens_minute: 0, closes_minute: 1)
    sign_in_new_device
    travel_to Time.zone.parse("2026-11-24 15:00") do
      post zone_path, params: { zone_number: 47, word: @venue.table_word }
      assert_response :unprocessable_content
      assert_match "closed", response.body
    end
  end

  test "area zones use only a rounded cell" do
    sign_in_new_device
    post zone_path, params: { cell_lat: "4071", cell_lng: "-7400" }
    assert_redirected_to root_path
    get root_path
    assert_response :success
    assert_select ".zone-pill", /Your area/
  end
end
