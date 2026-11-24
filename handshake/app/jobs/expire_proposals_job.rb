# Every minute: join and removal requests nobody answered in time.
class ExpireProposalsJob < ApplicationJob
  def perform
    MembershipProposal.overdue.find_each(&:expire!)
  end
end
