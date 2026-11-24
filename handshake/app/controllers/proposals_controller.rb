class ProposalsController < ApplicationController
  include ThreadScoped
  skip_before_action :load_thread, only: :waiting

  # The approval banner inside a chat (a Turbo frame that reloads on change).
  def index
    @proposals = @thread.pending_proposals.order(:created_at)
    render partial: "proposals/banner", locals: { proposals: @proposals, membership: @membership, thread: @thread }
  end

  # Propose removing someone.
  def create
    target = @thread.memberships.find_by(id: params[:membership_id])
    result = target ? MembershipProposal.propose_removal!(thread: @thread, target:, proposer: @membership) : :not_member
    notice = result.is_a?(MembershipProposal) ? "Asked the group." : "Couldn't ask the group to remove them."
    redirect_to chat_thread_path(@thread), notice:
  end

  def vote
    proposal = @thread.membership_proposals.find_by(id: params[:id])
    proposal&.vote!(@membership, params[:decision].to_s)
    DemoPartner.vote_on_proposals(@thread) if demo_mode?
    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.update("proposals", partial: "proposals/banner_body", locals: { proposals: @thread.pending_proposals.order(:created_at), membership: @membership, thread: @thread }) }
      format.html { redirect_to chat_thread_path(@thread) }
    end
  end

  # The newcomer's "waiting for the group" screen.
  def waiting
    @proposal = MembershipProposal.find_by(id: params[:id], subject_participant: current_participant)
    return redirect_to(root_path) unless @proposal
    return redirect_to(chat_thread_path(@proposal.chat_thread)) if @proposal.status == "approved" && @proposal.chat_thread.member?(current_participant)

    @proposal.evaluate!
  end
end
