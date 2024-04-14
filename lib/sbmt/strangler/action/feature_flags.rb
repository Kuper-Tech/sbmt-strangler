# frozen_string_literal: true

module Sbmt
  module Strangler
    class Action
      class FeatureFlags
        FLAGS = %i[
          replace_work_mode
          mirror_work_mode

          search
          search_compare
          render
          render_compare
        ]

        def initialize(action)
          @action = action
        end

        FLAGS.each do |flag_name|
          define_method flag_name do
            flag_name_with_prefix(flag_name)
          end
        end

        def add_all!
          FLAGS.each do |flag_name|
            feature_name = send(flag_name)
            Sbmt::Strangler::Flipper.add(feature_name)
          end
        end

        private

        def flag_name_with_prefix(flag_name)
          "#{@action.controller_name}##{@action.name} - #{flag_name}"
        end
      end
    end
  end
end
