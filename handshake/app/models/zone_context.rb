# The zone a person is "in" right now. Kept only in their encrypted session
# cookie (never in the database) and dropped after a few hours.
class ZoneContext
  LIFETIME = 6.hours

  attr_reader :zone_number, :neighbors, :label, :venue_id, :expires_at

  def initialize(zone_number:, neighbors: [], label: nil, venue_id: nil, expires_at: LIFETIME.from_now)
    @zone_number = Integer(zone_number)
    @neighbors = Array(neighbors).map { Integer(it) }
    @label = label
    @venue_id = venue_id
    @expires_at = expires_at.is_a?(String) ? Time.zone.parse(expires_at) : expires_at
  end

  def self.for_zone(zone)
    new(zone_number: zone.zone_number, neighbors: zone.neighbor_numbers, label: zone.label, venue_id: zone.venue_id)
  end

  def self.for_area(zone_number, neighbors)
    new(zone_number:, neighbors:, label: "Your area")
  end

  def self.load(hash)
    return if hash.blank?

    context = new(**hash.symbolize_keys.slice(:zone_number, :neighbors, :label, :venue_id, :expires_at))
    context unless context.expired?
  rescue ArgumentError, TypeError
    nil
  end

  def dump
    { "zone_number" => zone_number, "neighbors" => neighbors, "label" => label,
      "venue_id" => venue_id, "expires_at" => expires_at.iso8601 }
  end

  def expired? = expires_at.nil? || expires_at.past?

  # Neighbouring zones are accepted so people either side of a boundary can connect.
  def accepts?(number) = number == zone_number || neighbors.include?(number)

  def venue_zone? = Zone::VENUE_RANGE.cover?(zone_number)
end
