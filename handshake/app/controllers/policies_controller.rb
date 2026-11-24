class PoliciesController < ApplicationController
  include ThreadScoped

  def update
    outcome = @thread.change_policy!(@membership, params[:approval_policy].to_s)
    notice = { applied: "Updated.", proposed: "Suggested. It changes once everyone picks it.", unchanged: "No change." }[outcome]
    redirect_to chat_thread_people_path(@thread), notice:
  rescue ArgumentError
    redirect_to chat_thread_people_path(@thread), alert: "Pick one of the options."
  end
end
