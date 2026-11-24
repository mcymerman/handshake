require_relative "boot"

require "rails"
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "action_controller/railtie"
require "action_view/railtie"
require "action_cable/engine"
require "rails/test_unit/railtie"

Bundler.require(*Rails.groups)

module Handshake
  class Application < Rails::Application
    config.load_defaults 8.1
    config.autoload_lib(ignore: %w[assets tasks])

    # Random uuids everywhere: counting-up ids would reveal how few people use the site.
    config.generators { |g| g.orm :active_record, primary_key_type: :uuid }

    config.time_zone = ENV.fetch("APP_TIME_ZONE", "Eastern Time (US & Canada)")
    config.active_job.queue_adapter = :solid_queue

    # Action Cable logs broadcast payloads (message text) at debug level. Keep it quiet.
    config.action_cable.logger = ActiveSupport::Logger.new(STDOUT, level: :warn)
  end
end
