# frozen_string_literal: true

module Sbmt
  module Strangler
    class Action
      module Composition
        module Metrics
          private

          def with_metrics(rails_controller:, part: nil)
            result = nil
            with_yabeda_duration_measurement(rails_controller: rails_controller, part: part) do
              with_open_telemetry_tracing(part: part) do
                result = yield
              end
            end
            result
          end

          def with_yabeda_duration_measurement(rails_controller:, part: nil)
            result = nil
            yabeda_tags = {
              step: name.to_s,
              part: part&.to_s,
              type: type.to_s,
              level: level.to_s,
              parent: parent&.name&.to_s,
              controller: rails_controller.controller_path,
              action: rails_controller.action_name
            }
            Yabeda.sbmt_strangler.composition_step_duration.measure(yabeda_tags) do
              result = yield
            end
            result
          end

          def with_open_telemetry_tracing(part: nil)
            return yield unless Object.const_defined?(:OpenTelemetry)

            span_name = "Composition step: #{name}"
            span_name += " (#{part})" unless part.nil?

            span_attrs = {type: type.to_s, level: level}
            span_attrs[:parent] = parent.name.to_s unless parent.nil?

            result = nil
            ::OpenTelemetry.tracer_provider.tracer("Sbmt::Strangler")
              .in_span(span_name, attributes: span_attrs, kind: :internal) do |_span|
                result = yield
              end
            result
          end
        end
      end
    end
  end
end
