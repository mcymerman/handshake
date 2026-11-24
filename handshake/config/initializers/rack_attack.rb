# Rate limits and lockouts for code entry (see HandshakeGuard).
class Rack::Attack
  # In memory only: counters (hashed IPs, device digests, zone numbers) are
  # never written to disk and vanish when their window ends. With several
  # app servers each keeps its own counts; see README "Known limitations".
  self.cache.store = ActiveSupport::Cache::MemoryStore.new(size: 32.megabytes)

  GUARDED = ->(req) { req.post? && %w[/code_entries /zone].include?(req.path) }

  # Volume limits, whatever the outcome.
  throttle("code-entry/device", limit: 30, period: 60) do |req|
    HandshakeGuard.device_key(ActionDispatch::Request.new(req.env)) if GUARDED.call(req)
  end

  throttle("code-entry/ip", limit: 60, period: 60) do |req|
    HandshakeGuard.ip_key(req.ip) if GUARDED.call(req)
  end

  throttle("welcome/ip", limit: 20, period: 60) do |req|
    HandshakeGuard.ip_key(req.ip) if req.post? && req.path == "/welcome"
  end

  # Too many wrong codes: this device rests for 5 minutes.
  blocklist("locked-device") do |req|
    GUARDED.call(req) && HandshakeGuard.device_locked?(HandshakeGuard.device_key(ActionDispatch::Request.new(req.env)))
  end

  # Too many wrong codes from one network address: it rests for 10 minutes.
  blocklist("locked-ip") do |req|
    GUARDED.call(req) && HandshakeGuard.ip_locked?(req.ip)
  end

  # Working through table words from one address: zone entry rests 15 minutes.
  blocklist("locked-words") do |req|
    req.post? && req.path == "/zone" && req.params["word"].present? && HandshakeGuard.words_locked?(req.ip)
  end

  # Guessing storm in one zone: that zone pauses for 2 minutes.
  blocklist("paused-zone") do |req|
    req.post? && req.path == "/code_entries" &&
      HandshakeGuard.zone_paused?(HandshakeCode.parse(req.params["code"])&.first)
  end

  RESPONSES = {
    "locked-device" => "Too many tries. Take a breather: this device can enter codes again in 5 minutes.",
    "locked-ip" => "Too many tries from this network. Please wait 10 minutes and try again.",
    "locked-words" => "Too many wrong table words from this network. Please wait 15 minutes, or scan the QR code instead.",
    "paused-zone" => "This zone is paused for a couple of minutes because of unusual activity. Try again shortly."
  }.freeze

  def self.friendly(req, text)
    if req.get_header("HTTP_ACCEPT").to_s.include?("turbo-stream")
      body = %(<turbo-stream action="update" target="entry_status"><template><p class="status status-warn" role="alert">#{ERB::Util.html_escape(text)}</p></template></turbo-stream>)
      [ 429, { "content-type" => "text/vnd.turbo-stream.html" }, [ body ] ]
    else
      [ 429, { "content-type" => "text/plain" }, [ text ] ]
    end
  end

  self.blocklisted_responder = lambda do |req|
    friendly(req, RESPONSES.fetch(req.env["rack.attack.matched"], "Please slow down."))
  end

  self.throttled_responder = lambda do |req|
    friendly(req, "Whoa, that's a lot of codes. Wait a minute and try again.")
  end
end
