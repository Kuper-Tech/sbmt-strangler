# frozen_string_literal: true

module Sbmt
  module Strangler
    module WorkModes
      class Base
        attr_reader :rails_controller, :strangler_action, :metric_tracker, :feature_flags

        def initialize(rails_controller:, strangler_action:, metric_tracker:, feature_flags:)
          @rails_controller = rails_controller
          @strangler_action = strangler_action
          @metric_tracker = metric_tracker
          @feature_flags = feature_flags
        end

        def call
          raise NotImplementedError
        end
      end
    end
  end
end
