# frozen_string_literal: true

module Sbmt
  module Strangler
    class ActionInvoker
      module WorkModes
        module Proxy
          private

          def proxy_work_mode
            proxy_response = http_request(http_params)
            render_proxy_response(proxy_response)
          end
        end
      end
    end
  end
end
