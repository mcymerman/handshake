class ExtensionsController < ApplicationController
  include ThreadScoped

  def create
    extended = @thread.request_extension!(@membership)
    notice = extended ? "Extended by 14 days." : "Noted. It extends once everyone taps Extend."
    redirect_to chat_thread_path(@thread), notice:
  end
end
