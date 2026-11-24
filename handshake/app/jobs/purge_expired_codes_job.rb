# Every minute: delete codes (and their zone numbers) a minute after they
# expire or are used. Worst case about two minutes.
class PurgeExpiredCodesJob < ApplicationJob
  def perform
    HandshakeCode.purgeable.delete_all
  end
end
