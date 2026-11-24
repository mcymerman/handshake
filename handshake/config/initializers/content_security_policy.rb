# Strict Content Security Policy: our own scripts and styles only (importmap
# uses a nonce), images from us or data: URLs (QR codes, downscaled photos).
Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self
    policy.font_src    :self
    policy.img_src     :self, :data
    policy.object_src  :none
    policy.script_src  :self
    policy.style_src   :self
    policy.connect_src :self, (Rails.env.development? ? "ws://localhost:*" : :self)
    policy.frame_ancestors :none
    policy.base_uri :self
    policy.form_action :self
  end

  config.content_security_policy_nonce_generator = ->(_request) { SecureRandom.base64(16) }
  config.content_security_policy_nonce_directives = %w[script-src style-src]
  config.content_security_policy_nonce_auto = true
end

Rails.application.config.permissions_policy do |policy|
  policy.camera      :none
  policy.microphone  :none
  policy.geolocation :self
  policy.payment     :none
  policy.usb         :none
end
