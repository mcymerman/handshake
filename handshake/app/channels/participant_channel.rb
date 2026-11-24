# Personal stream: match redirects, alerts and code refreshes. Only the
# device itself may listen, even if someone copied the signed stream name.
class ParticipantChannel < Turbo::StreamsChannel
  def subscribed
    stream_name = verified_stream_name_from_params
    if stream_name && stream_name == self.class.send(:stream_name_from, Broadcasts.participant_stream(current_participant))
      stream_from stream_name
    else
      reject
    end
  end
end
