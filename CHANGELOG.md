# Change Log

## [1.0.8]
### Fixed
- Resolving artifacts from unstable channel properly map the product name to the relative package name when querying Artifactory.

## [1.0.7]
### Changed
- Relax all gemspec dependency versions

## [1.0.6]
### Changed
- Exclude metadata.json files from Artifactory package queries

## [1.0.5]
### Fixed
- Return chef.bintray.com based urls for el5 artifacts.

## [1.0.4]
### Fixed
- use `SHA256Managed` instead of `SHA256CryptoServiceProvider` to be compatible with .Net 2.0 which is the default runtime on Windows 2008 R2

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
