# Demo mode only: a bot friend to try every flow alone.
class DemoController < ApplicationController
  include ThreadScoped
  skip_before_action :load_thread, only: :friend
  before_action -> { head :not_found unless demo_mode? }
  before_action :require_zone, only: :friend

  def friend
    code, = current_personal_code
    _bot, @bot_display = DemoPartner.invite!(person: current_participant, my_code: code, zone_number: zone_context.zone_number)
    flash[:demo_code] = @bot_display
    redirect_to root_path
  end

  def newcomer
    result = DemoPartner.newcomer!(thread: @thread, sponsor: @membership)
    notice = result.is_a?(MembershipProposal) ? "A demo newcomer asked to join. Approve or decline below." : "Can't add a demo newcomer right now."
    redirect_to chat_thread_path(@thread), notice:
  end
end
