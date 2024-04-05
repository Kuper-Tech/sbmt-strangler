# frozen_string_literal: true

module Sbmt
  module Strangler
    class Action
      extend Sbmt::Strangler::Configurable

      option :params_tracking_allowlist, :headers_allowlist, default_from: :@controller

      attr_accessor :proxy_url, :proxy_http_verb
      attr_reader :name

      def initialize(name, controller, &)
        @name = name
        @controller = controller

        yield(self)
      end
    end
  end
end
