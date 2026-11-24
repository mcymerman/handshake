# Area zones (50-99) for places without a venue code.
#
# The phone rounds its own location to a grid cell of 0.01 degrees (about
# 1.1 km north-south) before sending anything, so the server never sees a
# precise position. We turn the cell into a zone number plus its 8
# neighbours' numbers, and then forget the cell.
module AreaZone
  RANGE = (50..99)
  MAX_INDEX = 18_000 # 180 degrees / 0.01

  module_function

  def number_for(lat_index, lng_index)
    RANGE.first + (OpenSSL::Digest::SHA256.hexdigest("#{lat_index}:#{lng_index}").to_i(16) % RANGE.size)
  end

  # Returns [zone_number, neighbour_numbers] or nil for an impossible cell.
  def for_cell(lat_index, lng_index)
    lat = Integer(lat_index, exception: false)
    lng = Integer(lng_index, exception: false)
    return unless lat && lng && lat.abs <= MAX_INDEX / 2 && lng.abs <= MAX_INDEX

    neighbours = [ -1, 0, 1 ].product([ -1, 0, 1 ]).filter_map do |dlat, dlng|
      number_for(lat + dlat, lng + dlng) unless dlat.zero? && dlng.zero?
    end
    zone = number_for(lat, lng)
    [ zone, (neighbours - [ zone ]).uniq.sort ]
  end
end
