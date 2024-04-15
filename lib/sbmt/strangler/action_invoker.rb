# frozen_string_literal: true

require_relative "action_invoker/work_modes/proxy"
require_relative "action_invoker/work_modes/mirror"
require_relative "action_invoker/work_modes/replace"

module Sbmt
  module Strangler
    class ActionInvoker
      include Sbmt::Strangler::ActionInvoker::WorkModes::Proxy
      include Sbmt::Strangler::ActionInvoker::WorkModes::Mirror
      include Sbmt::Strangler::ActionInvoker::WorkModes::Replace

      PROXY_WORK_MODE = :proxy
      MIRROR_WORK_MODE = :mirror
      REPLACE_WORK_MODE = :replace

      def initialize(action, rails_controller)
        @action = action
        @rails_controller = rails_controller
      end

      delegate(
        :logger, :render,
        :http_params, :http_request, :render_proxy_response,
        :track_params_usage, :track_work_mode,
        :track_search_accuracy, :track_render_accuracy,
        to: :@rails_controller
      )

      def call
        track_params_usage

        work_mode = choose_work_mode
        track_work_mode(work_mode)

        case work_mode
        when REPLACE_WORK_MODE then replace_work_mode
        when MIRROR_WORK_MODE then mirror_work_mode
        when PROXY_WORK_MODE then proxy_work_mode
        end
      end

      private

      def choose_work_mode
        return REPLACE_WORK_MODE if enabled?(@action.feature_flags.replace_work_mode)
        return MIRROR_WORK_MODE if enabled?(@action.feature_flags.mirror_work_mode)
        PROXY_WORK_MODE
      end

      def enabled?(feature_name)
        @rails_controller.flipper_feature_enabled_anyhow?(feature_name)
      end
    end
  end
end
