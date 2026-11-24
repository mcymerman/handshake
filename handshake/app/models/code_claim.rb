# "I typed your code." A connection needs a claim in both directions.
class CodeClaim < ApplicationRecord
  belongs_to :handshake_code
  belongs_to :participant
end
