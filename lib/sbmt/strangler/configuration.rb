# frozen_string_literal: true

module Sbmt
  module Strangler
    class Configuration
      extend Sbmt::Strangler::Configurable

      option :params_tracking_allowlist, :headers_allowlist, default: []
      option :action_controller_base_class, default: "ActionController::Base"
      option :error_tracker, default: "Sbmt::Strangler::ErrorTracker"
      option :logger, default: "Sbmt::Strangler::Logger"

      attr_reader :controllers, :http

      def initialize(options = {})
        @controllers = []
        @http = ActiveSupport::OrderedOptions.new.tap do |c|
          c.client = "Sbmt::Strangler::Http::Client"
          c.keepalive_pool_size = Sbmt::Strangler::Http::DEFAULT_KEEPALIVE_POOL_SIZE
          c.keepalive_idle_timeout = Sbmt::Strangler::Http::DEFAULT_KEEPALIVE_IDLE_TIMEOUT
          c.timeout = Sbmt::Strangler::Http::DEFAULT_TIMEOUT
          c.read_timeout = Sbmt::Strangler::Http::DEFAULT_READ_TIMEOUT
          c.write_timeout = Sbmt::Strangler::Http::DEFAULT_WRITE_TIMEOUT
          c.open_timeout = Sbmt::Strangler::Http::DEFAULT_OPEN_TIMEOUT
        end
      end

      def controller(name, &)
        @controllers.push(Sbmt::Strangler::Controller.new(name, self, &))
      end
    end
  end
end
