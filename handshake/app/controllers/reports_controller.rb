class ReportsController < ApplicationController
  include ThreadScoped

  def new
    @others = @membership.others.to_a
  end

  def thanks
    @thread_id = @thread.id
    @group = @thread.group?
  end

  def create
    permitted = params.require(:report).permit(:membership_id, :reason, :note, :include_evidence)
    reported = @membership.others.find_by(id: permitted[:membership_id])
    Report.file!(reporter: @membership, reported:, reason: permitted[:reason], note: permitted[:note],
                 include_evidence: permitted[:include_evidence] == "1")
    redirect_to thanks_chat_thread_reports_path(@thread)
  rescue ActiveRecord::RecordInvalid
    @others = @membership.others.to_a
    flash.now[:alert] = "Please choose a reason."
    render :new, status: :unprocessable_content
  end
end
