# Change Log

## [2.1.4]
- Fix Cumulus Linux and Cumulus Networks platform detection

## [2.1.3]
- Collection of software dependencies and license content is now configurable. Disabled by default.

## [2.1.2]
- Add Cumulus Linux and Cumulus Networks platform support
- Fix Arista EOS platform detection ordering

## [2.1.1]
- Add `mixlib-install` command line utility

## [2.1.0]
- Added new attributes to ArtifactInfo
 - product_name, product_description, license, license_content, software_dependencies
- Added static `#available_versions` method to API
- Architecture normalization cleanup
- Fixed race condition in acceptance suites

## [2.0.4]
- Normalize auto detect platform architectures

## [2.0.3]
- Add harmony as a supported product

## [2.0.2]
- Fix install.sh to include fetch_package.sh

## [2.0.1]
- Fix install.sh and install.ps1 scripts to install unstable packages

## [2.0.0]
- Replaced all backends with PackageRouter
- All channels are now available using the single backend
- Enabled unstable channel for install.sh and install.ps1 scripts
- Added chef-acceptance test suites and configured them to run in Travis
- Relaxed several test dependency versions

## [1.2.3]
- Add inspec as a supported product

## [1.2.2]
- Add a .gitattributes file to ensure files are checked out with lf line endings

## [1.2.1]
- Fix nano appx installs replacing the symlink with a full copy

## [1.2.0]
- Fix omnibus project mappings
- Add `available_versions` method to API
- Add `chef-automate` product
- Add install support for Arista EOS
- Add p5p package support
- Add s390x architecture support
- Add Nano support

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
