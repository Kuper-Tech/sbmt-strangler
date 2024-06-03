# frozen_string_literal: true

module Sbmt
  module Strangler
    class Controller
      extend Sbmt::Strangler::Configurable

      option :params_tracking_allowlist, :headers_allowlist, :flipper_actor, default_from: :configuration

      attr_reader :name, :class_name, :actions, :configuration

      def initialize(name, configuration, &)
        @name = name
        @class_name = "#{name.camelize}Controller"
        @actions = []
        @configuration = configuration

        yield(self)
      end

      def action(name, &)
        @actions.push(Sbmt::Strangler::Action.new(name, self, &))
      end

      def http
        @http ||= ActiveSupport::InheritableOptions.new(configuration.http)
      end
    end
  end
end
