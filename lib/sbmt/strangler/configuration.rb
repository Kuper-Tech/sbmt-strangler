# frozen_string_literal: true

module Sbmt
  module Strangler
    class Configuration
      extend Sbmt::Strangler::Configurable

      option :params_tracking_allowlist, :headers_allowlist, default: []
      option :action_controller_base_class, default: "ActionController::Base"
      option :error_tracker, default: "Sbmt::Strangler::ErrorTracker"
      option :flipper_actor, default: ->(_http_params, _headers) {}
      option :composition_step_duration_metric_buckets, default: nil

      attr_reader :controllers, :http

      def initialize(options = {})
        @controllers = []
        @http = ActiveSupport::InheritableOptions.new(Sbmt::Strangler::Http::DEFAULT_HTTP_OPTIONS)
      end

      def controller(name, &)
        controllers.push(Sbmt::Strangler::Controller.new(name, self, &))
      end
    end
  end
end
