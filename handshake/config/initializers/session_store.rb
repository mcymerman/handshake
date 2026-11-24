# The session cookie is encrypted and signed by Rails. It holds the zone you
# chose and the code on your screen, so it expires after 12 idle hours.
Rails.application.config.session_store :cookie_store,
  key: "_handshake",
  same_site: :lax,
  httponly: true,
  secure: Rails.env.production? && ENV.fetch("FORCE_SSL", "true") != "false",
  expire_after: 12.hours
