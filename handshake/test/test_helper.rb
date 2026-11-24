ENV["RAILS_ENV"] ||= "test"
ENV["DEMO_MODE"] ||= "false"
require_relative "../config/environment"
require "rails/test_help"

module HandshakeTestHelpers
  def new_participant(**attrs)
    Participant.create_with_token!(age_confirmed_at: Time.current, **attrs).first
  end

  def zone_ctx(number = 47, neighbors: [ 48 ])
    ZoneContext.new(zone_number: number, neighbors:, label: "Test")
  end

  # Returns [code, "47-12-83"].
  def issue(participant, zone = 47, **opts)
    HandshakeCode.issue!(participant:, zone_number: zone, **opts)
  end

  def enter(participant, display, ctx = zone_ctx)
    CodeEntry.new(participant:, zone_context: ctx, input: display).call
  end

  # A full mutual handshake. Returns the new thread.
  def connect!(a, b, zone = 47)
    _, a_display = issue(a, zone)
    _, b_display = issue(b, zone)
    assert_equal :waiting, enter(a, b_display, zone_ctx(zone)).status
    result = enter(b, a_display, zone_ctx(zone))
    assert_equal :matched, result.status
    result.thread
  end

  # A wrong code that is guaranteed not to exist in the zone.
  def unused_display(zone = 47)
    loop do
      digits = format("%04d", SecureRandom.random_number(10_000))
      return HandshakeCode.format(zone, digits) unless HandshakeCode.lookup(zone, digits)
    end
  end

  def seed_venue(zone_number: 47, opens: nil, closes: nil, neighbors: [ 48 ])
    venue, token = Venue.create_with_dashboard_token!(name: "Test Cafe #{zone_number}")
    venue.zones.create!(zone_number:, label: "Test Cafe", neighbor_numbers: neighbors, opens_minute: opens, closes_minute: closes)
    [ venue, token ]
  end
end

module ActiveSupport
  class TestCase
    parallelize(workers: :number_of_processors)
    include HandshakeTestHelpers
    include ActionCable::TestHelper

    setup { HandshakeGuard.reset! }
  end
end

module ActionDispatch
  class IntegrationTest
    def sign_in_new_device
      post welcome_path, params: { adult: "1" }
      assert_redirected_to root_path
      Participant.order(:created_at).last
    end

    def choose_zone(venue, zone_number = venue.zones.first.zone_number)
      post zone_path, params: { zone_number:, word: venue.table_word }
      assert_redirected_to root_path
    end
  end
end
