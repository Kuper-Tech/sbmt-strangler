# frozen_string_literal: true

require_relative "action/composition/step"

module Sbmt
  module Strangler
    class Action
      extend Sbmt::Strangler::Configurable

      option :params_tracking_allowlist, :headers_allowlist, :flipper_actor, default_from: :controller
      option :proxy_url
      option :proxy_http_method, default: :get
      option :mirror, default: ->(_rails_controller) {}
      option :compare, default: ->(_origin_result, _mirror_result) { false }
      option :render, default: ->(mirror_result) { mirror_result }

      attr_reader :name, :controller

      def initialize(name, controller, &)
        @name = name
        @controller = controller

        yield(self)
      end

      def full_name
        "#{controller.name}##{name}"
      end

      def http
        @http ||= ActiveSupport::InheritableOptions.new(controller.http)
      end

      def http_client
        @http_client ||= Sbmt::Strangler::Http::Client.new(http_options: http)
      end

      def composition(&)
        if block_given?
          @composition ||= Composition::Step.new(name: :root)
          yield(@composition)
        end
        @composition
      end

      def composition?
        !composition.nil?
      end
    end
  end
end
