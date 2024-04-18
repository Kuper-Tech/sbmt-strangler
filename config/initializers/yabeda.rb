# frozen_string_literal: true

module Sbmt
  module Strangler
    module Metrics
      module Yabeda
        HTTP_BUCKETS = [0.01, 0.02, 0.04, 0.1, 0.2, 0.5, 0.8, 1, 1.5, 2, 5, 15, 30, 60].freeze

        ::Yabeda.configure do
          group :sbmt_strangler do
            histogram :http_request_duration,
              tags: %i[name method status host path],
              unit: :seconds,
              buckets: HTTP_BUCKETS,
              comment: "HTTP client request duration"

            counter :params_usage,
              comment: "Parameters usage counter",
              tags: %i[params controller action]
            counter :work_mode,
              comment: "Work mode counter (mode: proxy, mirror, replace)",
              tags: %i[mode params controller action]
            counter :mirror_call,
              comment: "Mirror lambda call counter (success: true, false)",
              tags: %i[success params controller action]
            counter :compare_call,
              comment: "Compare lambda call counter (success: true, false)",
              tags: %i[success params controller action]
            counter :compare_result,
              comment: "Compare lambda successfull call result counter (value: true, false)",
              tags: %i[value params controller action]
          end
        end
      end
    end
  end
end
