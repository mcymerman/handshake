# First visit: the age gate and terms. Creates the anonymous device.
class WelcomeController < ApplicationController
  skip_before_action :require_participant

  def show
    redirect_to root_path if current_participant
  end

  def create
    unless params[:adult] == "1"
      flash.now[:alert] = "Handshake is for adults. Please confirm you're 18 or older."
      return render :show, status: :unprocessable_content
    end

    participant, token = Participant.create_with_token!(age_confirmed_at: Time.current)
    sign_in_device!(token)
    @current_participant = participant
    redirect_to(session.delete(:return_to) || root_path)
  end
end
