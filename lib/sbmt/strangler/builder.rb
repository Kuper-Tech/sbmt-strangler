# frozen_string_literal: true

module Sbmt
  module Strangler
    class Builder
      class << self
        def call!(configuration = Sbmt::Strangler.configuration)
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
      end
    end
  end
end
