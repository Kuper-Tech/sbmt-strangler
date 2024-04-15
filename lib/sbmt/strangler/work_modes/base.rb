# frozen_string_literal: true

module Sbmt
  module Strangler
    module WorkModes
      class Base
        def self.name_for_metric
          name.demodulize.underscore
        end

        def initialize(action, rails_controller)
          @action = action
          @rails_controller = rails_controller
        end

        def call
          raise "Must be implemented in sub-class!"
        end

        private

        def enabled?(feature_name)
          @rails_controller.flipper_feature_enabled_anyhow?(feature_name)
        end

        def handle_error(err)
          Sbmt::Strangler.error_tracker.error(err)
          Sbmt::Strangler.logger.error(err)
        end
      end
    end
  end
end
