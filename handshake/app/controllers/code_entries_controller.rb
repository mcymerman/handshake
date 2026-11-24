# Typing someone's code. Responses are Turbo Streams that update the status line.
class CodeEntriesController < ApplicationController
  MESSAGES = {
    waiting: "Got it! Now they enter your code.",
    matched: "You're connected!",
    join_requested: "Asked the group. Hang on a moment.",
    invalid_format: "Codes have six digits, like 47-12-83.",
    not_found: "No code matches that. Check the digits and try again.",
    expired: "That code just expired. Ask for the new one.",
    own_code: "That's your own code. Enter theirs instead.",
    out_of_zone: "That code is from a different zone. Are you both in the same place?",
    already_used: "That code has already been used. Ask for a fresh one.",
    code_changed: "That code changed for safety. Ask them for their new one.",
    both_adding: "You're both showing add-in codes. One of you should show your own code instead.",
    thread_gone: "That chat isn't open any more.",
    already_member: "You're already in that chat.",
    already_pending: "You've already asked to join. Waiting for the group.",
    busy: "They're already adding someone. Try again in a minute.",
    thread_full: "That chat is full.",
    at_limit: "One of you has too many open chats. End one to start another.",
    no_zone: "Choose where you are first.",
    suspended: "This device can't start new chats."
  }.freeze

  before_action :require_zone

  def create
    result = CodeEntry.new(participant: current_participant, zone_context:, input: params[:code]).call
    if CodeEntry::COUNTED_FAILURES.include?(result.status)
      HandshakeGuard.record_failure!(device_key: HandshakeGuard.device_key(request), ip: request.ip,
                                     zone_number: HandshakeCode.parse(params[:code])&.first)
    end

    @status = result.status
    @message = MESSAGES.fetch(result.status)
    @tone = result.success? ? "ok" : "warn"
    @redirect = if result.status == :matched
      chat_thread_path(result.thread)
    elsif result.status == :join_requested
      waiting_proposal_path(result.proposal)
    end

    respond_to do |format|
      format.turbo_stream { render status: (result.success? ? :ok : :unprocessable_content) }
      format.html { redirect_to(@redirect || root_path, (result.success? ? :notice : :alert) => @message) }
    end
  end
end
