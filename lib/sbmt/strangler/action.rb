# frozen_string_literal: true

module Sbmt
  module Strangler
    class Action
      extend Sbmt::Strangler::Configurable

      option :params_tracking_allowlist, :headers_allowlist, :flipper_actor, default_from: :controller
      option :proxy_url, :proxy_http_verb
      option :mirror, default: ->(_rails_controller) {}
      option :mirror_compare, default: ->(_origin_response, _mirror_result) { false }

      attr_reader :name, :controller

      def initialize(name, controller, &)
        @name = name
        @controller = controller

        Sbmt::Strangler::FeatureFlags.new(strangler_action: self).add_all!

        yield(self)
      end
    end
  end
end
