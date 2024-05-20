# frozen_string_literal: true

module Sbmt
  module Strangler
    class FeatureFlags
      FLAGS = %i[
        mirror
        replace
      ]

      attr_reader :strangler_action, :rails_controller

      def initialize(strangler_action:, rails_controller: nil)
        @strangler_action = strangler_action
        @rails_controller = rails_controller
      end

      FLAGS.each do |flag_name|
        define_method(:"#{flag_name}?") { feature_enabled?(feature_name(flag_name)) }
      end

      def add_all!
        FLAGS.each { |flag_name| add(feature_name(flag_name)) }
      end

      private

      delegate :add, :enabled?, :enabled_on_time?, to: "Sbmt::Strangler::Flipper"

      FEATURE_NAME_SANITIZER = -> { _1.to_s.gsub(/[^A-Za-z0-9]+/, "-") }

      def feature_name(flag_name)
        sanitized_controller_name = FEATURE_NAME_SANITIZER.call(strangler_action.controller.name)
        sanitized_action_name = FEATURE_NAME_SANITIZER.call(strangler_action.name)
        sanitized_flag_name = FEATURE_NAME_SANITIZER.call(flag_name)

        "#{sanitized_controller_name}__#{sanitized_action_name}--#{sanitized_flag_name}"
      end

      def feature_enabled?(feature_name)
        enabled?(feature_name, flipper_actor) || enabled_on_time?(feature_name)
      end

      def flipper_actor
        @flipper_actor ||= strangler_action.flipper_actor.call(rails_controller.http_params, rails_controller.request.headers)
      end
    end
  end
end
