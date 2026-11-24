class MessagesController < ApplicationController
  include ThreadScoped

  def create
    body = params.require(:message).permit(:body)[:body].to_s.strip
    if body.present?
      @message = @thread.post!(@membership, body.first(Message::MAX_LENGTH))
      DemoPartner.react_to_message(@thread) if demo_mode? && @thread.memberships.size > 1
    end

    respond_to do |format|
      format.turbo_stream # clears the composer; the message itself arrives over the socket
      format.html { redirect_to chat_thread_path(@thread) }
    end
  end
end
