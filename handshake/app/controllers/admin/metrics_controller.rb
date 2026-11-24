module Admin
  class MetricsController < BaseController
    def index
      @days = (27.days.ago.to_date..Date.current).to_a.reverse
      @rows = Metric.where(day: @days.last..).group(:day, :key).sum(:count)
      @totals = Metric.totals
      started = @totals["chats_started"].to_i
      @rates = {
        "Back-and-forth rate (3+ messages each way)" => rate(@totals["back_and_forth"], started),
        "Second-conversation rate" => rate(@totals["second_conversations"], started),
        "Group formation rate" => rate(@totals["groups_formed"], started),
        "Reveal step 1 rate" => rate(@totals["reveal_step_1"], started)
      }
    end

    private

    def rate(part, whole) = whole.to_i.zero? ? "–" : "#{(100.0 * part.to_i / whole).round(1)}%"
  end
end
