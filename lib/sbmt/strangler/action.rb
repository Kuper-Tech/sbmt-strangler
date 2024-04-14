# frozen_string_literal: true

require_relative "action/feature_flags"

module Sbmt
  module Strangler
    class Action
      extend Sbmt::Strangler::Configurable

      option :params_tracking_allowlist, :headers_allowlist, default_from: :@controller

      option :search, default: -> {}
      option :search_compare, default: ->(_search_result, _proxy_response) { false }
      option :render, default: ->(_search_result) {}
      option :render_compare, default: ->(_render_result, _proxy_response) { false }

      attr_accessor :proxy_url, :proxy_http_verb
      attr_reader :name, :feature_flags

      def initialize(name, controller, &)
        @name = name
        @controller = controller

        @feature_flags = Sbmt::Strangler::Action::FeatureFlags.new(self)
        @feature_flags.add_all!

        yield(self)
      end

      def controller_name
        @controller.name
      end
    end
  end
end
