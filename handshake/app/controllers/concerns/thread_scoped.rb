# Loads a chat for its member. Anyone else gets a plain "not found", so a
# chat's existence is never confirmed to outsiders.
module ThreadScoped
  extend ActiveSupport::Concern

  included do
    before_action :load_thread
  end

  private

  def load_thread
    id = params[:chat_thread_id] || params[:id]
    @thread = current_participant.chat_threads.live.find_by(id:)
    @membership = @thread&.membership_for(current_participant)
    return if @membership

    respond_to do |format|
      format.html { redirect_to chat_threads_path, notice: "That chat has ended or isn't yours." }
      format.turbo_stream { head :not_found }
      format.any { head :not_found }
    end
  end
end
