# Choosing where you are. The zone is kept only in your session cookie.
class ZonesController < ApplicationController
  def new
  end

  # Typed zone + table word, or a rounded area cell from the phone.
  def create
    context = if params[:cell_lat].present?
      area_context
    else
      venue_context(params[:zone_number], params[:word])
    end

    if context.is_a?(ZoneContext)
      store(context)
      redirect_to root_path
    else
      flash.now[:alert] = context
      render :new, status: :unprocessable_content
    end
  end

  # Scanning the table-tent QR code.
  def scan
    venue = Venue.find_by(public_code: params[:public_code])
    zone = venue&.zones&.order(:zone_number)&.first
    if zone && venue.valid_qr_token?(params[:token])
      store(ZoneContext.for_zone(zone))
      redirect_to root_path
    else
      redirect_to new_zone_path, alert: "That table-tent code has changed. Ask staff for this week's, or type the zone and word."
    end
  end

  def destroy
    session.delete(:zone)
    session.delete(:code)
    redirect_to new_zone_path
  end

  private

  def store(context)
    session[:zone] = context.dump
    session.delete(:code)
  end

  def area_context
    zone_number, neighbors = AreaZone.for_cell(params[:cell_lat], params[:cell_lng])
    return "We couldn't read your area. Try again, or use a venue code." unless zone_number

    ZoneContext.for_area(zone_number, neighbors)
  end

  def venue_context(number, word)
    zone = Zone.find_by(zone_number: number.to_i) if number.to_s.match?(/\A\d{2}\z/)
    unless zone && zone.venue.valid_table_word?(word)
      HandshakeGuard.record_word_failure!(device_key: HandshakeGuard.device_key(request), ip: request.ip)
      return "That zone and those words don't match. Check the table tent and try again."
    end
    return "Zone #{zone.zone_number} is closed right now (#{zone.hours_label})." unless zone.open_now?

    ZoneContext.for_zone(zone)
  end
end
