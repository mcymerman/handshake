# Reports with minimal data: reason, note, alias and any evidence the
# reporter chose to attach. Admins cannot browse chats.
module Admin
  class ReportsController < BaseController
    def index
      @reports = Report.order(created_at: :desc).limit(200)
    end

    def update
      report = Report.find(params[:id])
      case params[:decision]
      when "resolve" then report.resolve!
      when "suspend"
        report.reported_participant&.suspend!
        report.resolve!
      end
      redirect_to admin_reports_path, notice: "Report updated."
    end
  end
end
