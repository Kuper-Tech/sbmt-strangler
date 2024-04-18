# frozen_string_literal: true

require_relative "base"

module Sbmt
  module Strangler
    module WorkModes
      class Replace < Base
        def call
          mirror_result = strangler_action.mirror.call(rails_controller)
          track_mirror_call(true)
          render json: mirror_result
        end

        private

        delegate :render, to: :rails_controller
        delegate :track_mirror_call, to: :metric_tracker
      end
    end
  end
end
