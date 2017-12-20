# Mixlib::Install Changes

<!-- latest_release 3.9.0 -->
## [v3.9.0](https://github.com/chef/mixlib-install/tree/v3.9.0) (2017-12-20)

#### Merged Pull Requests
- add amazon linux 2.0 platform detection support [#246](https://github.com/chef/mixlib-install/pull/246) ([wrightp](https://github.com/wrightp))
<!-- latest_release -->

## [v3.8.0](https://github.com/chef/mixlib-install/tree/v3.8.0) (2017-10-31)

#### Merged Pull Requests
- Add support for aarch64 [#244](https://github.com/chef/mixlib-install/pull/244) ([jeremiahsnapp](https://github.com/jeremiahsnapp))

## [v3.7.0](https://github.com/chef/mixlib-install/tree/v3.7.0) (2017-10-11)

#### Merged Pull Requests
- add #download_artifact method to Mixlib::Install API [#243](https://github.com/chef/mixlib-install/pull/243) ([wrightp](https://github.com/wrightp))

## [v3.6.0](https://github.com/chef/mixlib-install/tree/v3.6.0) (2017-09-15)

#### Merged Pull Requests
- add install.sh proxy support [#242](https://github.com/chef/mixlib-install/pull/242) ([wrightp](https://github.com/wrightp))

## [v3.5.1](https://github.com/chef/mixlib-install/tree/v3.5.1) (2017-09-08)

#### Merged Pull Requests
- Return nil when looking up non-existing products [#241](https://github.com/chef/mixlib-install/pull/241) ([adamleff](https://github.com/adamleff))
- v3.5.0 [#239](https://github.com/chef/mixlib-install/pull/239) ([wrightp](https://github.com/wrightp))
- download url override and checksum updates [#237](https://github.com/chef/mixlib-install/pull/237) ([wrightp](https://github.com/wrightp))

## [v3.4.0](https://github.com/chef/mixlib-install/tree/v3.4.0) (2017-08-22)

#### Merged Pull Requests
- Add install_strategy option to bootstrap install scripts [#232](https://github.com/chef/mixlib-install/pull/232) ([wrightp](https://github.com/wrightp))

## [v3.3.4](https://github.com/chef/mixlib-install/tree/v3.3.4) (2017-08-10)

#### Merged Pull Requests
- Fix Windows architecture detection [#231](https://github.com/chef/mixlib-install/pull/231) ([rlaveycal](https://github.com/rlaveycal))

## [v3.3.3](https://github.com/chef/mixlib-install/tree/v3.3.3) (2017-08-02)

#### Merged Pull Requests
- mixlib-versioning backwards compatability for PartialSemVer support [#229](https://github.com/chef/mixlib-install/pull/229) ([wrightp](https://github.com/wrightp))



## [3.3.2]
- Fix bug where calling `products_available_on_downloads_site` would corrupt the product map.

## [3.3.1]
- Add download_url_override and checksum options for powershell version of installer script
- Update powershell execution due to policy changes in Windows 8, Windows Server 2012, and Windows 8.1

## [3.3.0]
- `available_versions` now returns a sorted list of versions (per mixlib-versioning)

## [3.2.2]
- Fix issue [#206](https://github.com/chef/mixlib-install/issues/206) - Missing metadata now returns `nil`

## [3.2.1]
- Add support for direct URL downloads for Bourne install script

## [3.2.0]
- Add support for partial product versioning support ("11", 12", "12.1", etc.)
- Refactor and expose `#normalize_architecture`

## [3.1.0]
- Add support for Windows Nano 2016 (returns appx packages)

## [3.0.0]
- [Breaking API Change] `Options` validation added to ensure that when any platform option is set they are all provided (platform, platform_version, architecture)
- [Breaking API Change] The `platform_version_compatibility_mode` option will automatically be set to `true` when no platform options are provided
- [Breaking API Change] Queries for aritfacts that yield no results will raise an exception (`Mixlib::Install::Backend::ArtifactsNotFound`) versus returning an empty array
- New properties added to `Products`: `github_repo` and `downloads_product_page_url`
- New method for retrieving products that are available on downloads.chef.io: `PRODUCT_MATRIX.products_available_on_downloads_site`

## [2.1.12]
- Force powershell scripts to ASCII encode variables

## [2.1.11]
- Fix ScriptGenerator install script to use proper platform detection for Windows artifacts
- Artifact metadata now includes supported Windows Desktop versions

## [2.1.10]
- Backward and forward compatibility support for `automate` and `delivery` product versions.

## [2.1.9]
- Add `download_directory` option to powershell install script

## [2.1.8]
- Query performance optimizations
- Add ChefClientFeature support to the powershell install script

## [2.1.7]
- Add support for passing arguments to the MSI in install scripts
- Add platform version compatibility support for Windows (including desktop versions)
- Enable platform version compatibility option by default for the cli

## [2.1.6]
- Add `User-Agent` headers to all download requests
- CLI UX improvements
- Add basic architecture validation

## [2.1.5]
- Add `install_path` properties to the products inside PRODUCT_MATRIX.

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