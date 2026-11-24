# Per-venue daily counts. Numbers only; nothing links to a person.
class VenueDailyCount < ApplicationRecord
  belongs_to :venue

  # Small numbers could point at individuals, so 1-2 show as "fewer than 3".
  def self.display(count)
    return "0" if count.zero?

    count < 3 ? "fewer than 3" : count.to_s
  end
end
