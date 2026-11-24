# The default request line is `Started GET "/path" for 203.0.113.9 at ...`.
# We drop the IP and time, and mask secret path segments (venue QR tokens,
# staff dashboard tokens). Query strings are already filtered by
# filter_parameters through request.filtered_path.
module PrivacyLogging
  SECRET_SEGMENTS = %r{\A/(here|dash)/[^/?]+}

  def self.scrub_path(path)
    path.to_s.sub(SECRET_SEGMENTS) { "/#{Regexp.last_match(1)}/[FILTERED]" }
  end

  module StartedRequestMessage
    private

    def started_request_message(request)
      %(Started #{request.raw_request_method} "#{PrivacyLogging.scrub_path(request.filtered_path)}")
    end
  end
end

Rails::Rack::Logger.prepend(PrivacyLogging::StartedRequestMessage)

# SQL debug lines (development and test; production logs at info, which has
# no SQL) can inline literal values. Blank out anything zone- or code-shaped.
module PrivacyLogging
  SQL_SENSITIVE = /("?(?:zone_number|neighbor_numbers|digest|token_digest)"?\s*(?:=|IN|<>|!=)\s*)(\([^)]*\)|'[^']*'|\$\d+|-?\d+)/i

  def self.scrub_sql(text) = text.gsub(SQL_SENSITIVE, '\1[FILTERED]')

  module ScrubSql
    def debug(progname = nil, &block)
      progname = PrivacyLogging.scrub_sql(progname) if progname.is_a?(String)
      super
    end
  end
end

ActiveSupport.on_load(:active_record) do
  ActiveRecord::LogSubscriber.prepend(PrivacyLogging::ScrubSql)
end
