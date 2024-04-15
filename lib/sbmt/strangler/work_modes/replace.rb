# frozen_string_literal: true

require_relative "base"

module Sbmt
  module Strangler
    module WorkModes
      class Replace < Base
        def call
          search_result = @action.search.call
          render_result = @action.render.call(search_result)
          render json: render_result
        end

        private

        delegate :render, to: :@rails_controller
      end
    end
  end
end
