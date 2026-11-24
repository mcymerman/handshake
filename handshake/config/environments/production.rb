require "active_support/core_ext/integer/time"

Rails.application.configure do
  config.enable_reloading = false
  config.eager_load = true
  config.consider_all_requests_local = false
  config.action_controller.perform_caching = true

  # Fingerprinted assets can be cached forever.
  config.public_file_server.headers = { "cache-control" => "public, max-age=#{1.year.to_i}" }

  # TLS terminates at the proxy (Kamal proxy, Render, Fly). Every request is
  # treated as HTTPS, redirected to HTTPS, and gets HSTS plus secure cookies.
  # FORCE_SSL=false is only for running the production image over plain
  # http on your own machine (docker compose --profile prod). Never in a real deploy.
  config.assume_ssl = ENV.fetch("FORCE_SSL", "true") != "false"
  config.force_ssl = ENV.fetch("FORCE_SSL", "true") != "false"
  config.ssl_options = { redirect: { exclude: ->(request) { request.path == "/up" } } }

  # Log to STDOUT, no IPs, no codes, no message text (see config/initializers/privacy_logging.rb).
  config.log_tags = [ :request_id ]
  config.logger   = ActiveSupport::TaggedLogging.logger(STDOUT)
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info")
  config.silence_healthcheck_path = "/up"
  config.active_support.report_deprecations = false

  # Everything lives in the primary database.
  config.cache_store = :solid_cache_store
  config.active_job.queue_adapter = :solid_queue

  config.i18n.fallbacks = true
  config.active_record.dump_schema_after_migration = false
  config.active_record.attributes_for_inspect = [ :id ]

  # Only answer for our own host names (comma-separated), e.g. "handshake.example.com".
  if ENV["APP_HOSTS"].present?
    config.hosts = ENV["APP_HOSTS"].split(",").map(&:strip)
    config.host_authorization = { exclude: ->(request) { request.path == "/up" } }
  end
end
