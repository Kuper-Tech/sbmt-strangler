# frozen_string_literal: true

module Sbmt
  module Strangler
    class Builder
      attr_reader :configuration

      # @param configuration [Sbmt::Strangler::Configuration]
      def initialize(configuration)
        @configuration = configuration
      end

      def call!
        build_controllers
        add_feature_flags
      end

      def self.call!(configuration = Sbmt::Strangler.configuration)
        new(configuration).call!
      end

      private

      def build_controllers
        configuration.controllers.each do |controller|
          unless Object.const_defined?(controller.class_name)
            Sbmt::Strangler::ConstDefiner.call!(controller.class_name, Class.new(Sbmt::Strangler.action_controller_base_class))
          end

          controller.class_name.constantize.class_eval do
            include Sbmt::Strangler::Mixin

            controller.actions.each do |action|
              define_method(action.name) do
                @strangler_action = action

                Sbmt::Strangler::ActionInvoker.new(
                  rails_controller: self,
                  strangler_action: action,
                  metric_tracker: Sbmt::Strangler::MetricTracker.new(self),
                  feature_flags: Sbmt::Strangler::FeatureFlags.new(
                    rails_controller: self,
                    strangler_action: action
                  )
                ).call
              end
            end
          end
        end
      end

      def add_feature_flags
        configuration.controllers.each do |controller|
          controller.actions.each do |action|
            Sbmt::Strangler::FeatureFlags.new(strangler_action: action).add_all!
          rescue => error
            Sbmt::Strangler.logger.log_warn(
              "Unable to add feature flags for action #{action.full_name}: #{error}",
              error_class: error.class.name
            )
          end
        end
      end
    end
  end
end
