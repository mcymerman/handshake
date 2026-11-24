class ProposalVote < ApplicationRecord
  belongs_to :membership_proposal
  belongs_to :membership

  validates :decision, inclusion: { in: %w[approve decline] }
end
