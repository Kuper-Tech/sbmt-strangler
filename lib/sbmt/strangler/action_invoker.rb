# frozen_string_literal: true

module Sbmt
  module Strangler
    class ActionInvoker
      WORK_MODE = {
        proxy: "proxy"
      }.freeze

      def initialize(action, rails_controller)
        @action = action
        @rails_controller = rails_controller
      end

      delegate :http_params, :http_request, :render_proxy_response, :track_params_usage,
        :track_work_tactic, to: :@rails_controller

      def call
        track_params_usage
        track_work_tactic(WORK_MODE[:proxy])

        response = http_request(http_params)
        render_proxy_response(response)
      end
    end
  end
end
