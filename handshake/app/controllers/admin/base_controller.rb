# Admin pages sit behind HTTP Basic auth with ADMIN_PASSWORD. If it isn't
# set, admin is switched off entirely.
module Admin
  class BaseController < ApplicationController
    skip_before_action :require_participant
    before_action :authenticate_admin!
    layout "admin"

    private

    def authenticate_admin!
      password = ENV["ADMIN_PASSWORD"].to_s
      return head(:not_found) if password.length < 12

      authenticate_or_request_with_http_basic("Handshake admin") do |user, given|
        ActiveSupport::SecurityUtils.secure_compare(user, ENV.fetch("ADMIN_USER", "admin")) &
          ActiveSupport::SecurityUtils.secure_compare(given, password)
      end
    end
  end
end
