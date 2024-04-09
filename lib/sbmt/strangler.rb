# frozen_string_literal: true

require "rails"
require "dry-monads"
require "yabeda"
require "faraday"
require "faraday/net_http_persistent"
require "oj"

begin
  require "sentry-rails"
rescue LoadError
  # optional dependency
end

require_relative "strangler/configurable"
require_relative "strangler/action"
require_relative "strangler/controller"
require_relative "strangler/configuration"
require_relative "strangler/mixin"
require_relative "strangler/builder"
require_relative "strangler/action_invoker"
require_relative "strangler/const_definer"
require_relative "strangler/errors"
require_relative "strangler/error_tracker"
require_relative "strangler/logger"
require_relative "strangler/http"

require_relative "strangler/engine"

module Sbmt
  module Strangler
    module_function

    # Public: Configure strangler.
    #
    #   Sbmt::Strangler.configure do |config|
    #     config.controller(...) do |controller|
    #       controller.action(...) do {...}
    #     end
    #   end
    #
    # Yields Sbmt::Strangler::Configuration instance.
    def configure
      yield configuration if block_given?
    end

    # Public: Returns Sbmt::Strangler::Configuration instance.
    def configuration
      @configuration ||= Configuration.new
    end

    def action_controller_base_class
      @action_controller_base_class ||= configuration.action_controller_base_class.constantize
    end

    def error_tracker
      @error_tracker ||= configuration.error_tracker.constantize
    end

    def logger
      @logger ||= configuration.logger.constantize
    end
  end
end
