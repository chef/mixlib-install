# Change Log

## [1.0.3]
### Changed
- Artifactory credentials are no longer required.  A designated account has been hard-coded as default.
- Exception is raised if Bintray can not find the version for channel/product.

### Fixed
- freebsd 9 artifacts return chef.bintray.com based urls

## [1.0.2]
### Added
- Use 32 bit windows artifacts for 64-bit, when there is no 64-bit native artifact.

## [1.0.1]
### Fixed
- detect_platform method for Windows

### Changed
- added stopaction to kick in the catch statement if manifest is missing
- wait for msiexec to exit
- Replace md5sum checks with sha256 checks in install_command.ps1

## [1.0.0]
### Added
- Ability to query product artifacts from multiple channels
- Ability to generate installation scripts for `sh` and `ps1`
