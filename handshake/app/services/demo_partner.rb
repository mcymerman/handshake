# Demo mode (DEMO_MODE=true): a friendly bot so one person with one phone can
# try every flow at a pilot or sales demo. Bots are marked plan "demo", get
# no cookie, and are purged with idle devices.
class DemoPartner
  REPLIES = [
    "Hi! Nice to meet you properly 👋",
    "That was easier than swapping numbers.",
    "Ha, agreed. What brought you here today?",
    "I like that this chat vanishes on its own.",
    "Want to try the reveal ladder? Tap People.",
    "Good chatting! Add someone if you like, I'll say yes."
  ].freeze

  def self.enabled? = ActiveModel::Type::Boolean.new.cast(ENV.fetch("DEMO_MODE", Rails.env.development? ? "true" : "false"))

  def self.create_bot! = Participant.create_with_token!(plan: "demo", age_confirmed_at: Time.current, first_name: "Demo friend").first

  # A bot that has already "typed" your current code; enter its code to connect.
  # Returns [bot, display_code].
  def self.invite!(person:, my_code:, zone_number:)
    bot = create_bot!
    bot_code, display = HandshakeCode.issue!(participant: bot, zone_number:)
    CodeClaim.create!(handshake_code: my_code, participant: bot)
    [ bot, display, bot_code ]
  end

  # A bot newcomer asks to join through an add-in, so you can try approvals.
  def self.newcomer!(thread:, sponsor:)
    MembershipProposal.propose_add!(thread:, newcomer: create_bot!, proposer: sponsor, via: "demo")
  end

  # Bots reply, say yes to joins, and match reveal steps.
  def self.react_to_message(thread)
    bots = thread.memberships.joins(:participant).where(participants: { plan: "demo" })
    return if bots.empty?

    bot = bots.first
    bot.chat_thread.post!(bot, REPLIES[(thread.last_seq / 2) % REPLIES.size])
  end

  def self.vote_on_proposals(thread)
    thread.pending_proposals.find_each do |proposal|
      proposal.voters.joins(:participant).where(participants: { plan: "demo" }).find_each do |bot|
        proposal.vote!(bot, "approve")
      end
    end
  end

  def self.match_reveal(from:, to:)
    return unless to.participant.demo?

    RevealGrant.offer!(from: to, to: from, level: RevealGrant.offered(from, to))
  end
end
