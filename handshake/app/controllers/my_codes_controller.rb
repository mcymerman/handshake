# The code card (a Turbo frame) refreshes itself when the countdown ends.
class MyCodesController < ApplicationController
  before_action :require_zone

  def show
    @open = zone_open?
    @code, @display = current_personal_code if @open
    render partial: "home/code_card", locals: { code: @code, display: @display, open: @open }
  end

  # Full-screen code for showing across a loud room.
  def big
    @code, @display = current_personal_code
  end
end
