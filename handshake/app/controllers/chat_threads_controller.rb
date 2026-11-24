class ChatThreadsController < ApplicationController
  include ThreadScoped
  skip_before_action :load_thread, only: :index

  def index
    @memberships = current_participant.memberships.joins(:chat_thread).merge(ChatThread.live)
                                      .includes(chat_thread: :memberships).order("chat_threads.updated_at DESC")
    @waiting = MembershipProposal.pending.where(subject_participant: current_participant, kind: "add")
  end

  def show
    @messages = @membership.visible_messages.last(200)
    @others = @membership.others.to_a
  end

  # "End chat" in a one-to-one, "Leave" in a group.
  def destroy
    was_group = @thread.group?
    @membership.leave!
    Metric.bump(:chats_ended) unless was_group
    redirect_to chat_threads_path, notice: was_group ? "You left the group." : "Chat ended. It's gone for both of you."
  end
end
