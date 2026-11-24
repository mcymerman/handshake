require "test_helper"

class RateLimitTest < ActionDispatch::IntegrationTest
  setup do
    @venue, = seed_venue(zone_number: 47)
    sign_in_new_device
    choose_zone(@venue)
  end

  test "8 wrong codes lock the device for 5 minutes" do
    7.times do
      post code_entries_path, params: { code: unused_display }, as: :turbo_stream
      assert_response :unprocessable_content
    end
    post code_entries_path, params: { code: unused_display }, as: :turbo_stream
    post code_entries_path, params: { code: unused_display }, as: :turbo_stream
    assert_response :too_many_requests
    assert_match "5 minutes", response.body

    travel 6.minutes do
      post code_entries_path, params: { code: unused_display }, as: :turbo_stream
      assert_response :unprocessable_content
    end
  end

  test "typos are counted but a successful entry is not" do
    other = new_participant
    _, other_display = issue(other, 47)
    6.times { post code_entries_path, params: { code: unused_display }, as: :turbo_stream }
    post code_entries_path, params: { code: other_display }, as: :turbo_stream
    assert_response :success
  end

  test "more than 30 entries a minute from one device are throttled" do
    other = new_participant
    _, other_display = issue(other, 47)
    # Choosing the zone was entry 1 (zone + table word is guarded too).
    29.times { post code_entries_path, params: { code: other_display }, as: :turbo_stream }
    assert_response :success
    post code_entries_path, params: { code: other_display }, as: :turbo_stream
    assert_response :too_many_requests
  end

  test "one network address can't keep going with fresh devices" do
    HandshakeGuard::IP_FAILURES.times { |i| HandshakeGuard.record_failure!(device_key: "dev:fresh#{i}", zone_number: nil, ip: "127.0.0.1") }
    post code_entries_path, params: { code: unused_display }, as: :turbo_stream
    assert_response :too_many_requests
    assert_match "this network", response.body
  end

  test "table words can't be worked through from one address" do
    HandshakeGuard::WORD_FAILURES.times { |i| HandshakeGuard.record_word_failure!(device_key: "dev:w#{i}", ip: "127.0.0.1") }
    post zone_path, params: { zone_number: 47, word: @venue.table_word }
    assert_response :too_many_requests
  end

  test "the table words are two words and forgiving to type" do
    word = @venue.table_word
    assert_equal 2, word.split.size
    assert @venue.valid_table_word?(word.upcase.tr(" ", "-"))
    assert @venue.valid_table_word?(word.delete(" "))
    refute @venue.valid_table_word?(word.split.first)
  end

  test "a guessing storm pauses the zone for everyone for 2 minutes" do
    HandshakeGuard::ZONE_FAILURES.times { |i| HandshakeGuard.record_failure!(device_key: "dev:bot#{i}", zone_number: 47) }
    post code_entries_path, params: { code: unused_display }, as: :turbo_stream
    assert_response :too_many_requests
    assert_match "zone is paused", response.body

    travel 3.minutes do
      post code_entries_path, params: { code: unused_display }, as: :turbo_stream
      assert_response :unprocessable_content
    end
  end
end
