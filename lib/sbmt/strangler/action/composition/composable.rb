# frozen_string_literal: true

module Sbmt
  module Strangler
    class Action
      class Composition
        module Composable
          MAX_COMPOSITION_LEVEL = 2

          def initialize(composition_level: 0, &)
            if composition_level > MAX_COMPOSITION_LEVEL
              raise Sbmt::Strangler::Action::Composition::Errors::MaxCompositionLevelError
            end

            @composition_level = composition_level
            @sync_steps = {}
            @async_steps = {}

            block_given? ? yield(self) : self
          end

          def call(rails_controller, previous_responses: {})
            async_responses = async_steps.map do |name, step|
              Concurrent::Promises.future do
                result = step.call(rails_controller, previous_responses: previous_responses)
                {name => result}
              end
            end

            sync_responses = sync_steps.reduce(previous_responses) do |result, (name, step)|
              result.merge(name => step.call(rails_controller, previous_responses: result))
            end

            responses = async_responses.map(&:value).reduce(sync_responses) do |result, step_result|
              result.merge(step_result)
            end

            compose_block.call(responses)
          rescue => error
            Sbmt::Strangler.logger.error(error.message)
            Sbmt::Strangler.error_tracker.error(error)

            {}
          end

          def sync(name, &)
            @sync_steps[name] = Sbmt::Strangler::Action::Composition::Step.new(
              name: name,
              composition_level: composition_level + 1, &
            )
          end

          def async(name, &)
            @async_steps[name] = Sbmt::Strangler::Action::Composition::Step.new(
              name: name,
              composition_level: composition_level + 1, &
            )
          end

          def composable?
            @sync_steps.any? || @async_steps.any?
          end

          def compose(&block)
            @compose_block = block
          end

          private

          attr_reader :sync_steps, :async_steps, :composition_level, :compose_block
        end
      end
    end
  end
end
