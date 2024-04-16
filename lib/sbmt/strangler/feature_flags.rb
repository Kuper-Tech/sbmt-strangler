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
        define_method(:"#{flag_name}?") { enabled?(feature_name(flag_name)) }
      end

      def add_all!
        FLAGS.each { |flag_name| add(feature_name(flag_name)) }
      end

      private

      delegate :add, :enabled_for_actor?, :enabled_on_time?, to: "Sbmt::Strangler::Flipper"

      def feature_name(flag_name)
        "#{strangler_action.controller.name}##{strangler_action.name}:#{flag_name}"
      end

      def enabled?(feature_name)
        enabled_for_actor?(feature_name, flipper_actor) || enabled_on_time?(feature_name)
      end

      def flipper_actor
        @flipper_actor ||=
          begin
            actor = strangler_action.flipper_actor&.call(rails_controller.http_params, rails_controller.request.headers)
            actor.presence || SecureRandom.uuid
          end
      end
    end
  end
end
