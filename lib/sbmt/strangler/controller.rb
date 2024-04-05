# frozen_string_literal: true

module Sbmt
  module Strangler
    class Controller
      extend Sbmt::Strangler::Configurable

      option :params_tracking_allowlist, :headers_allowlist, default_from: :@configuration

      attr_reader :actions, :name

      def initialize(name, configuration, &)
        @name = "#{name.camelize}Controller"
        @actions = []
        @configuration = configuration

        yield(self)
      end

      def action(name, &)
        @actions.push(Sbmt::Strangler::Action.new(name, self, &))
      end
    end
  end
end
