# frozen_string_literal: true

require_relative "work_modes/proxy"
require_relative "work_modes/mirror"
require_relative "work_modes/replace"

module Sbmt
  module Strangler
    class ActionInvoker
      attr_reader :rails_controller, :strangler_action, :feature_flags

      def initialize(rails_controller:, strangler_action:, feature_flags:)
        @rails_controller = rails_controller
        @strangler_action = strangler_action
        @feature_flags = feature_flags
      end

      delegate :track_params_usage, :track_work_mode, to: :rails_controller

      def call
        track_params_usage
        track_work_mode(work_mode_class.name.demodulize.underscore)
        work_mode_class.new(
          rails_controller:,
          strangler_action:,
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
