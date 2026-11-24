module ApplicationCable
  # Identifies the device from its signed cookie. No cookie, no socket.
  class Connection < ActionCable::Connection::Base
    identified_by :current_participant

    def connect
      self.current_participant = Participant.find_by_token(cookies.signed[:hs_device]) || reject_unauthorized_connection
      reject_unauthorized_connection if current_participant.suspended?
    end
  end
end
