# frozen_string_literal: true

require_relative "base"

module Sbmt
  module Strangler
    module WorkModes
      class Proxy < Base
        def call
          origin_response = http_request(http_params)
          render_origin_response(origin_response)
        end

        private

        delegate :http_params, :http_request, :render_origin_response, to: :rails_controller
      end
    end
  end
end
