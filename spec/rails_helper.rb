# frozen_string_literal: true

# Engine root is used by rails_configuration to correctly
# load fixtures and support files
require "pathname"
ENGINE_ROOT = Pathname.new(File.expand_path("..", __dir__))

ENV["RAILS_ENV"] = "test" # rubocop:disable Rails/OverridingEnvVars

require "combustion"

begin
  Combustion.initialize! :action_controller do
    if ENV["LOG"].to_s.empty?
      config.logger = ActiveSupport::TaggedLogging.new(Logger.new(nil))
      config.log_level = :fatal
    else
      config.logger = ActiveSupport::TaggedLogging.new(Logger.new($stdout))
      config.log_level = :debug
    end

    config.i18n.available_locales = [:ru, :en]
    config.i18n.default_locale = :en
  end
rescue => e
  warn "💥 Failed to load the app: #{e.message}\n#{e.backtrace.join("\n")}"
  exit(1)
end

Rails.application.load_tasks

require "rspec/rails"
# Add additional requires below this line. Rails is not loaded until this point!
require "yabeda/rspec"
require "vcr"

Dir[Sbmt::Strangler::Engine.root.join("spec/support/**/*.rb")].sort.each { |f| require f }

VCR.configure do |c|
  c.cassette_library_dir = "spec/fixtures/vcr"
  c.hook_into :faraday
  c.configure_rspec_metadata!
  c.ignore_hosts "127.0.0.1", "localhost"
  c.default_cassette_options = {
    match_requests_on: %i[method body uri],
    allow_unused_http_interactions: false
  }
end

RSpec.configure do |config|
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!
end
