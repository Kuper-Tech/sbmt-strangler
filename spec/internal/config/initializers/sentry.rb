# frozen_string_literal: true

require "sentry-ruby"

SENTRY_DUMMY_DSN = "http://12345:67890@sentry.localdomain/sentry/42"
Sentry.init do |config|
  config.dsn = SENTRY_DUMMY_DSN
  config.enabled_environments = [Rails.env]
  config.logger = Logger.new(nil)
  config.background_worker_threads = 0
  config.transport.transport_class = Sentry::DummyTransport
  config.traces_sample_rate = 1.0
end
