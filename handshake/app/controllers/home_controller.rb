# The main screen: your code, and a box for theirs.
class HomeController < ApplicationController
  before_action :require_zone

  def show
    @open = zone_open?
    @code, @display = current_personal_code if @open
    @pending_proposal = MembershipProposal.pending.where(subject_participant: current_participant, kind: "add").order(:created_at).last
    @chat_count = current_participant.live_threads.count
  end
end
