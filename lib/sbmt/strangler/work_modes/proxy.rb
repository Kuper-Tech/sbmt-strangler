# frozen_string_literal: true

require_relative "base"

module Sbmt
  module Strangler
    module WorkModes
      class Proxy < Base
        def call
          proxy_response = http_request(http_params)
          render_proxy_response(proxy_response)
        end

        private

        delegate :http_params, :http_request, :render_proxy_response, to: :@rails_controller
      end
    end
  end
end
