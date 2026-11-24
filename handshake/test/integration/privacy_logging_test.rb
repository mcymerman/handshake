require "test_helper"

# The brief: no codes, message text, zones, locations or IPs in logs.
class PrivacyLoggingTest < ActionDispatch::IntegrationTest
  setup do
    @venue, = seed_venue(zone_number: 38, neighbors: [])
    @io = StringIO.new
    @logger = ActiveSupport::Logger.new(@io, level: :debug)
    Rails.logger.broadcast_to(@logger)
    @previous_ar_level = ActiveRecord::Base.logger&.level
  end

  teardown { Rails.logger.stop_broadcasting_to(@logger) }

  test "a full handshake, chat and report leave no secrets in the logs" do
    ip = "203.0.113.77"
    alice = open_session
    bob = open_session
    [ alice, bob ].each do |s|
      s.post welcome_path, params: { adult: "1" }, env: { "REMOTE_ADDR" => ip }
      s.post zone_path, params: { zone_number: 38, word: @venue.table_word }, env: { "REMOTE_ADDR" => ip }
      s.get root_path, env: { "REMOTE_ADDR" => ip }
    end
    alice_code = alice.css_select("#my_code .code").first.text.delete(" ")
    bob_code = bob.css_select("#my_code .code").first.text.delete(" ")

    alice.post code_entries_path, params: { code: bob_code }, as: :turbo_stream, env: { "REMOTE_ADDR" => ip }
    bob.post code_entries_path, params: { code: alice_code }, as: :turbo_stream, env: { "REMOTE_ADDR" => ip }
    thread = ChatThread.last
    alice.post chat_thread_messages_path(thread), params: { message: { body: "secret pancake recipe" } }, as: :turbo_stream
    alice.post zone_path, params: { cell_lat: "4071", cell_lng: "-7400" }
    alice.get venue_dashboard_path("not-a-real-token-xyz")

    log = @io.string
    assert log.length > 1_000, "the log was captured"
    [ alice_code, bob_code ].each do |code|
      refute_includes log, code
      refute_includes log, code.delete("-")
      # The 4 personal digits as a standalone number. (Random request ids and
      # uuids can contain any 4-digit run by chance, so we don't match inside them.)
      refute_match(/(?<![\w.-])#{code.delete("-")[2, 4]}(?![\w.])/, log)
    end
    refute_includes log, "secret pancake"
    refute_includes log, ip
    refute_includes log, "4071"
    refute_includes log, "-7400"
    refute_includes log, @venue.table_word
    refute_includes log, "not-a-real-token-xyz"
    refute_match(/zone_number"?\s*(=|IN)\s*\(?38/, log)
    refute_match(/"zone_number"(, | => )38/, log)
  end
end
