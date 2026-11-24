# "My details": what you could choose to share, one person at a time.
class ProfilesController < ApplicationController
  def edit
  end

  def update
    if current_participant.update(params.require(:participant).permit(:first_name, :photo_data, :social_handles, :phone))
      redirect_to edit_profile_path, notice: "Saved. Nothing is shared until you and one other person both agree."
    else
      render :edit, status: :unprocessable_content
    end
  end

  # Deletes the device, its chats (for 1:1s, for both people) and its details.
  def destroy
    current_participant.erase!
    cookies.delete(DEVICE_COOKIE)
    reset_session
    redirect_to welcome_path, notice: "Everything about this device is deleted."
  end
end
