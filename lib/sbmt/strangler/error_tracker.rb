# frozen_string_literal: true

module Sbmt
  module Strangler
    class ErrorTracker
      class << self
        def error(message, params = {})
          unless defined?(Sentry)
            Sbmt::Strangler.logger.log_error(message, params)
            return
          end

          logging(:error, message, params)
        end

        private

        def logging(level, message, params)
          params = {message: params} if params.is_a?(String)

          Sentry.with_scope do |scope|
            scope.set_contexts(contexts: params)

            if message.is_a?(Exception)
              Sentry.capture_exception(message, level: level)
            else
              Sentry.capture_message(message, level: level)
            end
          end
        end
      end
    end
  end
end
