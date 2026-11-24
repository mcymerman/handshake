# Active Record Encryption protects message text and reveal details at rest.
# Production: set the three AR_ENCRYPTION_* variables (generate them with
# `bin/rails db:encryption:init`). Elsewhere, keys are derived from
# secret_key_base so development and tests need no setup.
Rails.application.configure do
  derive = ->(salt) { Rails.application.key_generator.generate_key("handshake/ar-encryption/#{salt}", 32).unpack1("H*") }

  config.active_record.encryption.primary_key =
    ENV["AR_ENCRYPTION_PRIMARY_KEY"].presence || derive.call("primary")
  config.active_record.encryption.deterministic_key =
    ENV["AR_ENCRYPTION_DETERMINISTIC_KEY"].presence || derive.call("deterministic")
  config.active_record.encryption.key_derivation_salt =
    ENV["AR_ENCRYPTION_KEY_DERIVATION_SALT"].presence || derive.call("salt")
end
