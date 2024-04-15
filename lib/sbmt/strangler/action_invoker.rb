# frozen_string_literal: true

require_relative "work_modes/proxy"
require_relative "work_modes/mirror"
require_relative "work_modes/replace"

module Sbmt
  module Strangler
    class ActionInvoker
      def initialize(action, rails_controller)
        @action = action
        @rails_controller = rails_controller
      end

      delegate :track_params_usage, :track_work_mode, to: :@rails_controller

      def call
        track_params_usage
        work_mode_class = choose_work_mode_class
        track_work_mode(work_mode_class.name_for_metric)
        work_mode_class.new(@action, @rails_controller).call
      end

      private

      def choose_work_mode_class
        return Sbmt::Strangler::WorkModes::Replace if enabled?(@action.feature_flags.replace_work_mode)
        return Sbmt::Strangler::WorkModes::Mirror if enabled?(@action.feature_flags.mirror_work_mode)
        Sbmt::Strangler::WorkModes::Proxy
      end

      def enabled?(feature_name)
        @rails_controller.flipper_feature_enabled_anyhow?(feature_name)
      end
    end
  end
end
