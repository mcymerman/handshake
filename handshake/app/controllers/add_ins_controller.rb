# "Add someone": show a one-time thread code and type the newcomer's code.
class AddInsController < ApplicationController
  include ThreadScoped
  before_action :require_zone

  def show
    return redirect_to(chat_thread_path(@thread), alert: "This chat is full.") if @thread.open_seats <= 0

    stored = session[:add_in] || {}
    @code = HandshakeCode.live.find_by(id: stored["id"], chat_thread: @thread, participant: current_participant) if stored["thread"] == @thread.id
    @code = nil if @code&.expires_at&.past?
    if @code
      @display = stored["display"]
    else
      @code, @display = HandshakeCode.issue!(participant: current_participant, zone_number: zone_context.zone_number,
                                             kind: "add_in", chat_thread: @thread)
      session[:add_in] = { "id" => @code.id, "thread" => @thread.id, "display" => @display }
    end
    render partial: "add_ins/card", locals: { code: @code, display: @display } if turbo_frame_request?
  end
end
