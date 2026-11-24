# Chat stream. Signed stream names stop guessing; the membership check stops
# a removed member from listening with a stream name they kept.
class ChatThreadChannel < Turbo::StreamsChannel
  def subscribed
    stream_name = verified_stream_name_from_params
    thread = stream_name && GlobalID::Locator.locate(stream_name, only: ChatThread)
    if thread&.live? && thread.member?(current_participant)
      stream_from stream_name
    else
      reject
    end
  rescue ActiveRecord::RecordNotFound, URI::InvalidURIError
    reject
  end
end
