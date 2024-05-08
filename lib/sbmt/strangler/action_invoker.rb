# frozen_string_literal: true

module Sbmt
  module Strangler
    class ActionInvoker
      attr_reader :rails_controller, :strangler_action, :metric_tracker, :feature_flags

      def initialize(rails_controller:, strangler_action:, metric_tracker:, feature_flags:)
        @rails_controller = rails_controller
        @strangler_action = strangler_action
        @metric_tracker = metric_tracker
        @feature_flags = feature_flags
      end

      delegate :track_params_usage, :track_work_mode, :log_unallowed_params, to: :metric_tracker

      def call
        track_params_usage
        log_unallowed_params
        track_work_mode(work_mode_class.name.demodulize.underscore)
        work_mode_class.new(
          rails_controller:,
          strangler_action:,
          metric_tracker:,
          feature_flags:
        ).call
      end

      private

      def work_mode_class
        @work_mode_class ||=
          if feature_flags.replace?
            Sbmt::Strangler::WorkModes::Replace
          elsif feature_flags.mirror?
            Sbmt::Strangler::WorkModes::Mirror
          else
            Sbmt::Strangler::WorkModes::Proxy
          end
      end
    end
  end
end
