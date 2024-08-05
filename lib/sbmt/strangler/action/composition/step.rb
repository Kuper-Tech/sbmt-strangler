# frozen_string_literal: true

module Sbmt
  module Strangler
    class Action
      class Composition
        class Step
          include Composable

          def initialize(name:, composition_level: 0, &)
            @name = name

            super(composition_level: composition_level, &)
          end

          def call(rails_controller, previous_responses: {})
            result = begin
              process_lambda.call(rails_controller, previous_responses)
            rescue => error
              Sbmt::Strangler.logger.error(error.message)
              Sbmt::Strangler.error_tracker.error(error)

              {}
            end

            # process composition if there are nested steps
            if composable?
              result = super(rails_controller, previous_responses: previous_responses.merge(name => result))
            end

            result
          end

          def process(&block)
            @process_lambda = block

            self
          end

          def with_composition(&)
            yield(self)
          end

          private

          attr_reader :process_lambda, :name
        end
      end
    end
  end
end
