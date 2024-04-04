# frozen_string_literal: true

require_relative 'lib/sbmt/strangler/version'

Gem::Specification.new do |spec|
  spec.name = 'sbmt-strangler'
  spec.version = Sbmt::Strangler::VERSION
  spec.authors = ['sbermarket team']

  spec.summary = 'Utility for strangler pattern'
  spec.description = spec.summary
  spec.homepage = 'https://gitlab.sbmt.io/nstmrt/rubygems/sbmt-strangler'
  spec.required_ruby_version = '>= 3.0.0'

  spec.metadata['allowed_push_host'] = 'https://nexus.sbmt.io'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = "#{spec.homepage}/-/blob/master/CHANGELOG.md"
  spec.metadata['rubygems_mfa_required'] = 'false' # rubocop:disable Gemspec/RequireMFA

  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'faraday', '> 1.0'
  spec.add_dependency 'faraday-net_http_persistent', '> 1.0'
  spec.add_dependency 'net-http-persistent', '>= 4.0.1'

  spec.add_dependency 'flipper'
  spec.add_dependency 'railties', '>= 6.1', '< 7.2'
  spec.add_dependency 'sentry-rails', '>= 5.3.1'
  spec.add_dependency 'yabeda', '>= 0.11'
  spec.add_dependency 'yabeda-prometheus-mmap', '~> 0.3'
  spec.add_dependency 'oj'
  spec.add_dependency 'dry-monads'
  spec.add_dependency 'dry-struct'

  spec.add_dependency 'sbmt-app', '>= 1.34.0'

  spec.add_development_dependency 'appraisal', '>= 2.4'
  spec.add_development_dependency 'bundler', '>= 2.3'
  spec.add_development_dependency 'combustion', '>= 1.3'
  spec.add_development_dependency 'rake', '>= 13.0'
  spec.add_development_dependency 'sbmt-dev', '~> 0.14'
end
