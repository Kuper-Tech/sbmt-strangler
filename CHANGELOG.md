# Change Log

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).

## [0.?.?] - 2024-04-??

### Added
- add support for mirror and replace modes
- add config options: action.mirror, action.compare, configuration.flipper_actor
- add to Mixin: #track_mirror_call, #track_compare_call, #track_compare_result

### Changed
- rename Mixin#render_proxy_response to Mixin#render_origin_response
- rename Mixin#track_work_tactic to Mixin#track_work_mode

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
