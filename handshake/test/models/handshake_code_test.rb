require "test_helper"

class HandshakeCodeTest < ActiveSupport::TestCase
  test "issues a three-pair code and stores only a keyed hash" do
    person = new_participant
    code, display = issue(person, 47)

    assert_match(/\A47-\d{2}-\d{2}\z/, display)
    digits = display.delete("-")[2, 4]
    assert_equal HandshakeCode.digest_for(47, digits), code.digest
    refute_includes code.attributes.values.map(&:to_s).join(" "), digits, "plain digits must never be stored"
    assert_equal code, HandshakeCode.lookup(47, digits)
  end

  test "codes are unique among live codes in a zone" do
    person = new_participant
    displays = Array.new(300) { issue(person, 47).last }
    assert_equal displays.size, displays.uniq.size
  end

  test "parses common ways of typing a code" do
    assert_equal [ 47, "1283" ], HandshakeCode.parse("47-12-83")
    assert_equal [ 47, "1283" ], HandshakeCode.parse(" 47 12 83 ")
    assert_equal [ 47, "1283" ], HandshakeCode.parse("471283")
    assert_nil HandshakeCode.parse("47-12-8")
    assert_nil HandshakeCode.parse("abc")
  end

  test "expires about 60 seconds after issue, with a short grace" do
    code, = issue(new_participant)
    travel 65.seconds
    assert code.reload.live?, "accepted during the 10-second grace"
    travel 6.seconds
    refute code.reload.live?
  end

  test "purge deletes codes a minute after expiry or use" do
    person = new_participant
    expired, = issue(person)
    used, = issue(person)
    used.update!(consumed_at: Time.current)
    fresh_code = nil
    travel 3.minutes do
      fresh_code, = issue(person)
      PurgeExpiredCodesJob.perform_now
    end
    refute HandshakeCode.exists?(expired.id)
    refute HandshakeCode.exists?(used.id)
    assert HandshakeCode.exists?(fresh_code.id)
  end
end
