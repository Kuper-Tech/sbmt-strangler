# Change Log

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).

## [0.10.1] - 2024-09-02

### Fixed
- Use `Rails.application.executor.wrap` for application code running inside new thread

## [0.10.0] - 2024-08-05

### Added
- Add composition mode

## [0.9.2] - 2024-07-12

### Changed
- Now ONTIME flipper flags can work with any hours range
- Now hours range don't include last value to work

## [0.9.1] - 2024-07-02

### Added
- Add put request support

## [0.9.0] - 2024-06-06

### Added
- Add handler for Faraday::ConnectionFailed
- Add retry connection support

## [0.8.0] - 2024-06-05

### Added
- Add `action.render = ->(mirror_result) { ... }` lambda

## [0.7.0] - 2024-06-03

### Added
- allow to configure timeout per route

### Changed
- rename "proxy_http_verb" to "proxy_http_method"

## [0.6.0] - 2024-05-30

### Added
- add support for enabling work mode by request header

## [0.5.0] - 2024-05-22

### Added
- use [net_http_persistent](https://github.com/lostisland/faraday-net_http_persistent) for proxying

## [0.4.0] - 2024-05-22

### Added
- enable replace mode (it was temporarily commented out in the source code)
- in the replace mode a value returned from action.mirror block is passed directly to the #render method
- action.flipper_actor lambda can now return an array of actor IDs instead of a single actor ID

### Changed
- automatic feature flags name now has BEM-like formatting: "controller-path__action-name--work-mode" (because of Flipper UI limitations/recomendations)
- action.compare is called for failed origin/proxy responses too
- the first argument of action.compare block (called origin_result) is a hash of the form {body:, status:, headers:}
- metric renamed: sbmt_strangler_compare_result -> sbmt_strangler_compare_call_result

## [0.3.1] - 2024-04-24

### Fixed
- Create feature flags after the app fully initialized and handle flag creation errors

## [0.3.0] - 2024-04-22

### Added
- add support for mirror and replace modes
- add config options: action.mirror, action.compare, configuration.flipper_actor
- add to Mixin: #track_mirror_call, #track_compare_call, #track_compare_result

### Changed
- rename Mixin#render_proxy_response to Mixin#render_origin_response
- rename Mixin#track_work_tactic to Mixin#track_work_mode
- Sbmt::Strangler::Http::Transport#get|post_request returns response body as String (it skips parsing body as JSON).

### Fixed
- Fix from v0.2.2 ported to v0.3.0

## [0.2.2] - 2024-04-19

### Fixed
- filter out IDs like 'R608473650' from Faraday metric 'path' tag

## [0.2.0] - 2024-04-09

### Added
- add metrics for http client request

### Changed

### Fixed

## [0.1.1] - 2024-04-08

### Added

### Changed

### Fixed
- ignore inherit constants in Sbmt::Strangler::ConstDefiner

## [0.1.0] - 2024-04-05

### Added
- initial release with proxy tooling

### Changed

### Fixed
- ignore inherit constants in Sbmt::Strangler::ConstDefiner
