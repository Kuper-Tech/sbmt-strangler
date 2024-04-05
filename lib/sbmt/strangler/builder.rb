# frozen_string_literal: true

module Sbmt
  module Strangler
    class Builder
      class << self
        def call!(configuration = Sbmt::Strangler.configuration)
          configuration.controllers.each do |controller|
            unless Object.const_defined?(controller.name)
              Sbmt::Strangler::ConstDefiner.call!(controller.name, Class.new(Sbmt::Strangler.action_controller_base_class))
            end

            controller.name.constantize.class_eval do
              include Sbmt::Strangler::Mixin

              controller.actions.each do |action|
                define_method(action.name) do
                  @strangler_action = action

                  Sbmt::Strangler::ActionInvoker.new(action, self).call
                end
              end
            end
          end
        end
      end
    end
  end
end
