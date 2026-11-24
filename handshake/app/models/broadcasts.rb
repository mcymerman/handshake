# Real-time pushes over Action Cable. Every stream name is signed, and the
# channels re-check membership on subscribe.
module Broadcasts
  module_function

  def participant_stream(participant_or_id)
    id = participant_or_id.is_a?(Participant) ? participant_or_id.id : participant_or_id
    [ "participant", id ]
  end

  def visit(participant, path)
    Turbo::StreamsChannel.broadcast_stream_to(participant_stream(participant),
      content: %(<turbo-stream action="visit" location="#{ERB::Util.html_escape(path)}"><template></template></turbo-stream>))
  end

  def notice(participant, text, tone: "info")
    Turbo::StreamsChannel.broadcast_append_to(participant_stream(participant), target: "alerts",
      partial: "shared/alert", locals: { text:, tone: })
  end

  # Tells the code card to fetch a fresh code (after a match or an eavesdrop alert).
  def refresh_code(participant)
    Turbo::StreamsChannel.broadcast_stream_to(participant_stream(participant),
      content: %(<turbo-stream action="reload_frame" target="my_code"><template></template></turbo-stream>))
  end

  # Shows the reason, and moves the person off the chat if it's on screen.
  def chat_ended(participant_id, thread_id, reason)
    Turbo::StreamsChannel.broadcast_stream_to(participant_stream(participant_id),
      content: %(<turbo-stream action="leave_thread" target="thread_#{thread_id}" message="#{ERB::Util.html_escape(reason)}"><template></template></turbo-stream>))
  end

  def proposals_changed(thread)
    Turbo::StreamsChannel.broadcast_stream_to(thread,
      content: %(<turbo-stream action="reload_frame" target="proposals"><template></template></turbo-stream>))
  end

  # Drops a removed member's live connection so they stop receiving the
  # chat; on reconnect, ChatThreadChannel refuses them.
  def disconnect_from_thread(participant)
    ActionCable.server.remote_connections.where(current_participant: participant).disconnect(reconnect: true)
  end
end
