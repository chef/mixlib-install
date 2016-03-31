# Change Log
This change log follows the principles
outlined from [Keep a CHANGELOG](http://keepachangelog.com/).

All notable changes to this project will be documented in this file.
This project adheres to [Semantic Versioning](http://semver.org/).

## [Unreleased]
### Added
- Use 32 bit windows artifacts for 64-bit, when there is no 64-bit native artifact.

## [1.0.1] - 2016-03-31
### Fixed
- detect_platform method for Windows

### Changed
- added stopaction to kick in the catch statement if manifest is missing
- wait for msiexec to exit
- Replace md5sum checks with sha256 checks in install_command.ps1

## [1.0.0] - 2016-03-30
### Added
- Ability to query product artifacts from multiple channels
- Ability to generate installation scripts for `sh` and `ps1`

[Unreleased]: https://github.com/chef/mixlib-install/compare/v1.0.1...HEAD
[1.0.1]: https://github.com/chef/mixlib-install/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/chef/mixlib-install/compare/v0.7.1...v1.0.0
