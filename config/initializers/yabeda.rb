# frozen_string_literal: true

module Sbmt
  module Strangler
    module Metrics
      module Yabeda
        DEFAULT_BUCKETS = [0.01, 0.02, 0.04, 0.1, 0.2, 0.5, 0.8, 1, 1.5, 2, 5, 15, 30, 60].freeze
        HTTP_BUCKETS = DEFAULT_BUCKETS
        COMPOSITION_BUCKETS = DEFAULT_BUCKETS

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
            counter :compare_call_result,
              comment: "Compare lambda call result counter (value: true, false)",
              tags: %i[value params controller action]
            counter :render_call,
              comment: "Render lambda call counter (success: true, false)",
              tags: %i[success params controller action]
          end
        end
      end
    end
  end
end

# Declaring composition step duration metric in an `after_initialize` block
# allows user to customize buckets in his app-level configuration file:
#
#     # config/initializers/strangler.rb
#     Sbmt::Strangler.configure do |strangler|
#       strangler.composition_step_duration_metric_buckets = [0.1, 0.2, 0.3]
#     end
#
Rails.application.config.after_initialize do
  ::Yabeda.configure do
    group :sbmt_strangler do
      composition_buckets =
        ::Sbmt::Strangler.configuration.composition_step_duration_metric_buckets ||
        ::Sbmt::Strangler::Metrics::Yabeda::COMPOSITION_BUCKETS

      histogram :composition_step_duration,
        tags: %i[step part type level parent controller action],
        unit: :seconds,
        buckets: composition_buckets,
        comment: "Composition step duration"
    end
  end
end
