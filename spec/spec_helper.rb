# frozen_string_literal: true

ENV["RAILS_ENV"] = "test" # rubocop:disable Rails/OverridingEnvVars

require "bundler/setup"
require "rspec"
require "rspec_junit_formatter"

RSpec.configure do |config|
  config.filter_run_when_matching :focus
  config.example_status_persistence_file_path = "tmp/rspec_examples.txt"
  config.run_all_when_everything_filtered = true

  if config.files_to_run.one?
    # Use the documentation formatter for detailed output,
    # unless a formatter has already been configured
    # (e.g. via a command-line flag).
    config.default_formatter = "doc"
  end

  config.order = :random
  Kernel.srand config.seed
end
