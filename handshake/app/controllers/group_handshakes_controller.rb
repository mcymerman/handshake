# "Group handshake": a 2-minute code anyone nearby can enter. Joiners still
# need the group's approval.
class GroupHandshakesController < ApplicationController
  include ThreadScoped
  before_action :require_zone

  def show
    stored = session[:group_code] || {}
    @code = HandshakeCode.live.find_by(id: stored["id"], chat_thread: @thread) if stored["thread"] == @thread.id
    @display = stored["display"] if @code&.expires_at&.future?
  end

  def create
    return redirect_to(chat_thread_path(@thread), alert: "This chat is full.") if @thread.open_seats <= 0

    @code, @display = HandshakeCode.issue!(participant: current_participant, zone_number: zone_context.zone_number,
                                           kind: "group", chat_thread: @thread)
    session[:group_code] = { "id" => @code.id, "thread" => @thread.id, "display" => @display }
    @thread.post_system!("#{@membership.alias_name} opened a group handshake for 2 minutes. Anyone who joins still needs your yes.")
    redirect_to chat_thread_group_handshake_path(@thread)
  end
end
