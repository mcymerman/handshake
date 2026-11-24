class ApplicationController < ActionController::Base
  DEVICE_COOKIE = :hs_device

  allow_browser versions: :modern
  stale_when_importmap_changes

  before_action :require_participant
  helper_method :current_participant, :zone_context, :demo_mode?

  private

  def current_participant
    return @current_participant if defined?(@current_participant)

    @current_participant = Participant.find_by_token(cookies.signed[DEVICE_COOKIE])&.tap(&:touch_seen!)
  end

  def require_participant
    return if current_participant && !current_participant.suspended?

    if current_participant&.suspended?
      render "pages/suspended", status: :forbidden
    else
      session[:return_to] = request.fullpath if request.get?
      redirect_to welcome_path
    end
  end

  def sign_in_device!(token)
    cookies.signed.permanent[DEVICE_COOKIE] = {
      value: token, httponly: true, secure: Rails.application.config.force_ssl, same_site: :lax
    }
  end

  def zone_context
    @zone_context ||= ZoneContext.load(session[:zone])
  end

  def require_zone
    redirect_to new_zone_path unless zone_context
  end

  def demo_mode? = DemoPartner.enabled?

  # Codes shown on screen live only in the encrypted session cookie.
  # Returns [code_record, "47-12-83"] for the current personal code, issuing
  # a new one when the old one is used up, cancelled or expired.
  def current_personal_code
    stored = session[:code] || {}
    code = HandshakeCode.find_by(id: stored["id"], participant: current_participant) if stored["id"]
    if code && code.consumed_at.nil? && code.expires_at.future? && code.zone_number == zone_context.zone_number
      return [ code, stored["display"] ]
    end

    code, display = HandshakeCode.issue!(participant: current_participant, zone_number: zone_context.zone_number)
    session[:code] = { "id" => code.id, "display" => display }
    [ code, display ]
  end

  def zone_open?
    return true unless zone_context&.venue_zone?

    Zone.find_by(zone_number: zone_context.zone_number)&.open_now? || false
  end
  helper_method :zone_open?
end
