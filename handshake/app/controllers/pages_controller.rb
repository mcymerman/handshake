class PagesController < ApplicationController
  skip_before_action :require_participant

  def how; end
  def privacy; end
  def terms; end
end
