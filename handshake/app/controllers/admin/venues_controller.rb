module Admin
  class VenuesController < BaseController
    def index
      @venues = Venue.includes(:zones).order(:name)
    end

    def new
      @form = {}
    end

    def create
      @form = params.require(:venue).permit(:name, :zone_number, :label, :neighbors, :opens, :closes, :theme_label, :theme_wday, :theme_starts, :theme_ends).to_h
      Venue.transaction do
        @venue, @token = Venue.create_with_dashboard_token!(name: @form["name"])
        @venue.zones.create!(zone_number: @form["zone_number"], label: @form["label"].presence || @form["name"],
                             neighbor_numbers: @form["neighbors"].to_s.scan(/\d+/).map(&:to_i),
                             opens_minute: to_minute(@form["opens"]), closes_minute: to_minute(@form["closes"]),
                             theme_label: @form["theme_label"].presence, theme_wday: @form["theme_wday"].presence&.to_i,
                             theme_start_minute: to_minute(@form["theme_starts"]), theme_end_minute: to_minute(@form["theme_ends"]))
      end
      render :created
    rescue ActiveRecord::RecordInvalid => e
      flash.now[:alert] = e.record.errors.full_messages.to_sentence
      render :new, status: :unprocessable_content
    end

    private

    def to_minute(value)
      hours, minutes = value.to_s.split(":").map(&:to_i)
      value.present? ? (hours * 60) + minutes.to_i : nil
    end
  end
end
