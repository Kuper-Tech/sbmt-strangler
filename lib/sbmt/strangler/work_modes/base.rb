# frozen_string_literal: true

module Sbmt
  module Strangler
    module WorkModes
      class Base
        attr_reader :rails_controller, :strangler_action, :feature_flags

        def initialize(rails_controller:, strangler_action:, feature_flags:)
          @rails_controller = rails_controller
          @strangler_action = strangler_action
          @feature_flags = feature_flags
        end

        def call
          raise NotImplementedError
        end

        private

        def handle_error(err)
          Sbmt::Strangler.error_tracker.error(err)
          Sbmt::Strangler.logger.error(err)
        end
      end
    end
  end
end
