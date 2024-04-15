# frozen_string_literal: true

module Sbmt
  module Strangler
    class ActionInvoker
      module WorkModes
        module Replace
          private

          def replace_work_mode
            search_result = @action.search.call
            render_result = @action.render.call(search_result)
            render json: render_result
          end
        end
      end
    end
  end
end
