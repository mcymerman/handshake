# Failed-guess counting for lockouts. Rack::Attack enforces the locks
# (config/initializers/rack_attack.rb); the app records failures because
# only the app knows whether an entry matched a code.
#
# Keys hold a device-token digest or a zone number, and live only as long
# as the window or lock. IPs are hashed with a server secret.
module HandshakeGuard
  DEVICE_FAILURES = 8
  DEVICE_WINDOW = 5.minutes
  DEVICE_LOCK = 5.minutes
  # Per network address, so one address can't pause a zone or work through
  # table words, however many new devices it creates.
  IP_FAILURES = 30
  IP_WINDOW = 10.minutes
  IP_LOCK = 10.minutes
  WORD_FAILURES = 20
  WORD_WINDOW = 1.hour
  WORD_LOCK = 15.minutes
  ZONE_FAILURES = 60
  ZONE_WINDOW = 1.minute
  ZONE_PAUSE = 2.minutes

  module_function

  def store = Rack::Attack.cache.store

  def device_key(request)
    token = request.cookie_jar.signed[ApplicationController::DEVICE_COOKIE]
    token.present? ? "dev:#{Participant.digest_token(token)[0, 32]}" : "ip:#{ip_key(request.ip)}"
  end

  def ip_key(ip) = OpenSSL::HMAC.hexdigest("SHA256", secret, ip.to_s)[0, 32]
  def secret = @secret ||= Rails.application.key_generator.generate_key("handshake/ip-hash", 32)

  def record_failure!(device_key:, zone_number:, ip: nil)
    bump("hs:fail:#{device_key}", DEVICE_WINDOW, DEVICE_FAILURES, "hs:lock:#{device_key}", DEVICE_LOCK)
    bump("hs:fail:ip:#{ip_key(ip)}", IP_WINDOW, IP_FAILURES, "hs:lock:ip:#{ip_key(ip)}", IP_LOCK) if ip
    return unless zone_number

    zone_failures = store.increment("hs:fail:zone:#{zone_number}", 1, expires_in: ZONE_WINDOW).to_i
    store.write("hs:lock:zone:#{zone_number}", true, expires_in: ZONE_PAUSE) if zone_failures >= ZONE_FAILURES
  end

  def record_word_failure!(device_key:, ip:)
    bump("hs:fail:#{device_key}", DEVICE_WINDOW, DEVICE_FAILURES, "hs:lock:#{device_key}", DEVICE_LOCK)
    bump("hs:fail:words:#{ip_key(ip)}", WORD_WINDOW, WORD_FAILURES, "hs:lock:words:#{ip_key(ip)}", WORD_LOCK)
  end

  def bump(counter, window, limit, lock, lock_for)
    count = store.increment(counter, 1, expires_in: window).to_i
    store.write(lock, true, expires_in: lock_for) if count >= limit
  end

  def device_locked?(device_key) = store.exist?("hs:lock:#{device_key}")
  def ip_locked?(ip) = store.exist?("hs:lock:ip:#{ip_key(ip)}")
  def words_locked?(ip) = store.exist?("hs:lock:words:#{ip_key(ip)}")
  def zone_paused?(zone_number) = zone_number && store.exist?("hs:lock:zone:#{zone_number}")

  def reset! = store.clear
end
