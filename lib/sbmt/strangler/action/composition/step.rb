# frozen_string_literal: true

require_relative "metrics"
require_relative "errors/configuration_error"
require_relative "errors/max_level_error"

module Sbmt
  module Strangler
    class Action
      module Composition
        class Step
          include Metrics

          TYPES = %i[sync async].freeze
          MAX_LEVEL = 2

          attr_reader :name, :type, :level, :parent

          def initialize(name:, type: :sync, level: 0, parent: nil)
            if name.nil? || name.to_s == ""
              raise Errors::ConfigurationError, "Composition step name must be a non-empty string or symbol"
            end

            if TYPES.exclude?(type)
              raise Errors::ConfigurationError, "Composition step type must be a symbol from #{TYPES}"
            end

            if !parent.nil? && !parent.is_a?(self.class)
              raise Errors::ConfigurationError, "Composition step parent must be either #{self.class} or nil"
            end

            if !level.is_a?(Integer) && level >= 0
              raise Errors::ConfigurationError, "Composition step level must be a non-negative integer"
            end

            if level > MAX_LEVEL
              raise Errors::MaxLevelError, "Composition step is too deeply nested"
            end

            @name = name
            @type = type
            @level = level
            @parent = parent
            @sync_steps = {}
            @async_steps = {}
          end

          def call(rails_controller, previous_responses: {})
            with_metrics(rails_controller: rails_controller) do
              result = begin
                with_metrics(part: :process, rails_controller: rails_controller) do
                  process_lambda.call(rails_controller, previous_responses)
                end
              rescue => error
                handle_error(error)

                {} # TODO: Better error handling in composition.
              end

              # process composition if there are nested steps
              if composable?
                result = call_composition(rails_controller, previous_responses: previous_responses.merge(name => result))
              end

              result
            end
          end

          def sync(name, &)
            step = Sbmt::Strangler::Action::Composition::Step.new(
              name: name,
              type: :sync,
              parent: self,
              level: level + 1
            )
            yield(step) if block_given?
            @sync_steps[name] = step
            step
          end

          def async(name, &)
            step = Sbmt::Strangler::Action::Composition::Step.new(
              name: name,
              type: :async,
              parent: self,
              level: level + 1
            )
            yield(step) if block_given?
            @async_steps[name] = step
            step
          end

          def process(&block)
            @process_lambda = block
            self
          end

          def compose(&block)
            @compose_lambda = block
            self
          end

          alias_method :with_composition, :tap

          private

          attr_reader :sync_steps, :async_steps, :process_lambda, :compose_lambda

          def composable?
            @sync_steps.any? || @async_steps.any?
          end

          def call_composition(rails_controller, previous_responses: {})
            async_responses = async_steps.map do |name, step|
              Concurrent::Promises.future do
                Rails.application.executor.wrap do
                  result = step.call(rails_controller, previous_responses: previous_responses)
                  {name => result}
                end
              end
            end

            sync_responses = sync_steps.reduce(previous_responses) do |result, (name, step)|
              result.merge(name => step.call(rails_controller, previous_responses: result))
            end

            responses = async_responses.map(&:value).reduce(sync_responses) do |result, step_result|
              result.merge(step_result)
            end

            with_metrics(part: :compose, rails_controller: rails_controller) do
              compose_lambda.call(responses, rails_controller)
            end
          rescue => error
            handle_error(error)

            {} # TODO: Better error handling in composition.
          end

          def handle_error(error)
            Sbmt::Strangler.logger.error(error.message)
            Sbmt::Strangler.error_tracker.error(error)
          end
        end
      end
    end
  end
end
