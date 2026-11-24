# Venue staff pages, reached with a secret link. Counts only, never people.
class VenueDashboardsController < ApplicationController
  skip_before_action :require_participant
  before_action :load_venue
  content_security_policy(only: :live) { |policy| policy.img_src :self, :data }

  def show
    @days = (13.days.ago.to_date..Date.current).to_a.reverse
    @counts = @venue.venue_daily_counts.where(day: @days.last..).index_by(&:day)
    @zones = @venue.zones.order(:zone_number)
  end

  def tent
    @zones = @venue.zones.order(:zone_number)
    render layout: "print"
  end

  def live
    @zones = @venue.zones.order(:zone_number)
    render layout: "print"
  end

  private

  def load_venue
    @venue = Venue.find_by_dashboard_token(params[:token])
    head :not_found unless @venue
  end
end
