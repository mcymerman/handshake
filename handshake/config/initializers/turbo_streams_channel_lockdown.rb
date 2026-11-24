# Turbo's built-in channel accepts any valid signed stream name. Our signed
# names never change, so a removed member who kept one could re-subscribe
# through it and keep reading. Refuse everyone there; ParticipantChannel and
# ChatThreadChannel (which check permission and override this) are the only
# ways in.
Rails.application.config.to_prepare do
  Turbo::StreamsChannel.class_eval do
    def subscribed = reject
  end
end
