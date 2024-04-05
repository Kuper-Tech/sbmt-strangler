# frozen_string_literal: true

require_relative "lib/sbmt/strangler/version"

Gem::Specification.new do |spec|
  spec.name = "sbmt-strangler"
  spec.version = Sbmt::Strangler::VERSION
  spec.authors = ["sbermarket team"]

  spec.summary = "Utility for strangler pattern"
  spec.description = spec.summary
  spec.homepage = "https://gitlab.sbmt.io/nstmrt/rubygems/sbmt-strangler"
  spec.required_ruby_version = ">= 3.1.0"

  spec.metadata["allowed_push_host"] = "https://nexus.sbmt.io"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/-/blob/master/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "false" # rubocop:disable Gemspec/RequireMFA

  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "faraday", "> 2.0"
  spec.add_dependency "faraday-net_http_persistent", "~> 2.0"
  spec.add_dependency "net-http-persistent", ">= 4.0.1"
  spec.add_dependency "rails", ">= 6.1", "< 8"
  spec.add_dependency "yabeda", ">= 0.11"
  spec.add_dependency "oj"
  spec.add_dependency "dry-monads"
  spec.add_dependency "dry-struct"

  spec.add_development_dependency "appraisal"
  spec.add_development_dependency "bundler"
  spec.add_development_dependency "combustion"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "rspec-rails"
  spec.add_development_dependency "rspec_junit_formatter"
  spec.add_development_dependency "rubocop"
  spec.add_development_dependency "rubocop-rails"
  spec.add_development_dependency "rubocop-rspec"
  spec.add_development_dependency "rubocop-performance"
  spec.add_development_dependency "vcr"
  spec.add_development_dependency "standard", ">= 1.7"
  spec.add_development_dependency "zeitwerk"
  spec.add_development_dependency "sentry-rails", "> 5.2.0"
end
