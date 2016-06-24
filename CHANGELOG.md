# Change Log

## [1.1.0]
- Remove delivery-cli from Product Matrix since we are now shipping it within ChefDK

## [1.0.13]
- Fix Windows architecture detection for stable channel
- Added support for retrying project msi installation for exit code 1618 (another installation is in progress)

## [1.0.12]
- Normalize the architecture detection to return either x86_64, i386 or sparc.
- Remove the powershell product_name validation to support delivery-cli and push-jobs-client in install.ps1.
- Retry MSI installation when it fails with 1618 (another installation in progress).

## [1.0.11]
- Add `platform_version_compatibility_mode` option which makes mixlib-install select an artifact built for an earlier version of a platform when set.

## [1.0.10]
- Correctly parse architecture for ppc64el.
- Return chef.bintray.com based urls for solaris9 and solaris10.
- Handle historical artifacts published for solaris.

## [1.0.9]
- Update platform detection scripts to recognize debian 8 correctly.

## [1.0.8]
- Resolving artifacts from unstable channel properly map the product name to the relative package name when querying Artifactory.

## [1.0.7]
- Relax all gemspec dependency versions

## [1.0.6]
- Exclude metadata.json files from Artifactory package queries

## [1.0.5]
- Return chef.bintray.com based urls for el5 artifacts.

## [1.0.4]
- use `SHA256Managed` instead of `SHA256CryptoServiceProvider` to be compatible with .Net 2.0 which is the default runtime on Windows 2008 R2

## [1.0.3]
- Artifactory credentials are no longer required.  A designated account has been hard-coded as default.
- Exception is raised if Bintray can not find the version for channel/product.
- freebsd 9 artifacts return chef.bintray.com based urls

## [1.0.2]
- Use 32 bit windows artifacts for 64-bit, when there is no 64-bit native artifact.

## [1.0.1]
- detect_platform method for Windows
- added stopaction to kick in the catch statement if manifest is missing
- wait for msiexec to exit
- Replace md5sum checks with sha256 checks in install_command.ps1

## [1.0.0]
- Ability to query product artifacts from multiple channels
- Ability to generate installation scripts for `sh` and `ps1`
