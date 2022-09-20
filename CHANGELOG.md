# Mixlib::Install Changes

<!-- latest_release 3.12.21 -->
## [v3.12.21](https://github.com/chef/mixlib-install/tree/v3.12.21) (2022-09-20)

#### Merged Pull Requests
- Allow to extend the supported products of mixlib-install [#340](https://github.com/chef/mixlib-install/pull/340) ([Tensibai](https://github.com/Tensibai))
<!-- latest_release -->
<!-- release_rollup since=3.12.20 -->
### Changes not yet released to rubygems.org

#### Merged Pull Requests
- Allow to extend the supported products of mixlib-install [#340](https://github.com/chef/mixlib-install/pull/340) ([Tensibai](https://github.com/Tensibai)) <!-- 3.12.21 -->
<!-- release_rollup -->

<!-- latest_stable_release -->
## [v3.12.20](https://github.com/chef/mixlib-install/tree/v3.12.20) (2022-09-08)

#### Merged Pull Requests
- Match on 64 for architecture because of different languages [#380](https://github.com/chef/mixlib-install/pull/380) ([tpowell-progress](https://github.com/tpowell-progress))
<!-- latest_stable_release -->

## [v3.12.19](https://github.com/chef/mixlib-install/tree/v3.12.19) (2022-06-01)

#### Merged Pull Requests
- Test Ruby3.0/3.1- IPACK-66 [#375](https://github.com/chef/mixlib-install/pull/375) ([poorndm](https://github.com/poorndm))
- Add ruby 3.0/3.1 tests on windows [#378](https://github.com/chef/mixlib-install/pull/378) ([poorndm](https://github.com/poorndm))
- Add support for amazon linux 2022 [#373](https://github.com/chef/mixlib-install/pull/373) ([jeremiahsnapp](https://github.com/jeremiahsnapp))

## [v3.12.16](https://github.com/chef/mixlib-install/tree/v3.12.16) (2021-08-14)

#### Merged Pull Requests
- fetch_package.sh: fix backtick position for filename extraction [#369](https://github.com/chef/mixlib-install/pull/369) ([jeremy-clerc](https://github.com/jeremy-clerc))

## [v3.12.15](https://github.com/chef/mixlib-install/tree/v3.12.15) (2021-08-13)

#### Merged Pull Requests
- Strip query parameters before parsing URI path [#358](https://github.com/chef/mixlib-install/pull/358) ([gscho](https://github.com/gscho))
- Provide more helpful error messages when you need to provide more details [#352](https://github.com/chef/mixlib-install/pull/352) ([tas50](https://github.com/tas50))
- pin contracts to 0.16 [#367](https://github.com/chef/mixlib-install/pull/367) ([rishichawda](https://github.com/rishichawda))
- Update install script warning to not mention desktop [#366](https://github.com/chef/mixlib-install/pull/366) ([rishichawda](https://github.com/rishichawda))

## [v3.12.11](https://github.com/chef/mixlib-install/tree/v3.12.11) (2021-03-17)

#### Merged Pull Requests
- Remove pry-stack-explorer test dep [#349](https://github.com/chef/mixlib-install/pull/349) ([tas50](https://github.com/tas50))
- Test on Ruby 3.0 &amp; use Buildkite caching [#351](https://github.com/chef/mixlib-install/pull/351) ([tas50](https://github.com/tas50))
- Lock climate_control to 0.1.0 on older rubies [#354](https://github.com/chef/mixlib-install/pull/354) ([gscho](https://github.com/gscho))
- Strip query parameters when determining filename [#353](https://github.com/chef/mixlib-install/pull/353) ([gscho](https://github.com/gscho))

## [v3.12.7](https://github.com/chef/mixlib-install/tree/v3.12.7) (2021-02-19)

#### Merged Pull Requests
- fix windows tests [#338](https://github.com/chef/mixlib-install/pull/338) ([mwrock](https://github.com/mwrock))
- Fall back to Get-WmiObject if Get-CimInstance fails [#348](https://github.com/chef/mixlib-install/pull/348) ([gscho](https://github.com/gscho))

## [v3.12.5](https://github.com/chef/mixlib-install/tree/v3.12.5) (2020-11-02)

#### Merged Pull Requests
- Add linux path, variabilize script_generator and install [#333](https://github.com/chef/mixlib-install/pull/333) ([Tensibai](https://github.com/Tensibai))
- Ensure platform detection logic supports Apple Silicon [#336](https://github.com/chef/mixlib-install/pull/336) ([schisamo](https://github.com/schisamo))

## [v3.12.3](https://github.com/chef/mixlib-install/tree/v3.12.3) (2020-08-13)

#### Merged Pull Requests
- Fix minor spelling mistakes [#322](https://github.com/chef/mixlib-install/pull/322) ([tas50](https://github.com/tas50))
- Optimize requires for non-omnibus installs [#324](https://github.com/chef/mixlib-install/pull/324) ([tas50](https://github.com/tas50))

## [v3.12.1](https://github.com/chef/mixlib-install/tree/v3.12.1) (2020-03-12)

#### Merged Pull Requests
- Use the VERSION_ID variable by default in /etc/os-release [#313](https://github.com/chef/mixlib-install/pull/313) ([tas50](https://github.com/tas50))
- OS X -&gt; macOS [#311](https://github.com/chef/mixlib-install/pull/311) ([tas50](https://github.com/tas50))

## [v3.11.29](https://github.com/chef/mixlib-install/tree/v3.11.29) (2020-03-09)

#### Merged Pull Requests
- Map arm64 architecture to aarch64 [#309](https://github.com/chef/mixlib-install/pull/309) ([jaymalasinha](https://github.com/jaymalasinha))

## [v3.11.28](https://github.com/chef/mixlib-install/tree/v3.11.28) (2020-03-05)

#### Merged Pull Requests
- updated powershell template to support airgapped artifact environment… [#299](https://github.com/chef/mixlib-install/pull/299) ([Romascopa](https://github.com/Romascopa))
- Add support for arm64 architecture [#308](https://github.com/chef/mixlib-install/pull/308) ([jaymalasinha](https://github.com/jaymalasinha))

## [v3.11.26](https://github.com/chef/mixlib-install/tree/v3.11.26) (2019-12-30)

#### Merged Pull Requests
- Test on Ruby 2.7 + random testing improvements [#303](https://github.com/chef/mixlib-install/pull/303) ([tas50](https://github.com/tas50))
- Substitute require for require_relative [#305](https://github.com/chef/mixlib-install/pull/305) ([tas50](https://github.com/tas50))

## [v3.11.24](https://github.com/chef/mixlib-install/tree/v3.11.24) (2019-12-12)

#### Merged Pull Requests
- Add buildkite PR verification [#294](https://github.com/chef/mixlib-install/pull/294) ([tas50](https://github.com/tas50))
- Community distribution fixes [#292](https://github.com/chef/mixlib-install/pull/292) ([ramereth](https://github.com/ramereth))
- Properly identify Windows 2019 in the install.ps1 [#301](https://github.com/chef/mixlib-install/pull/301) ([tas50](https://github.com/tas50))

## [v3.11.21](https://github.com/chef/mixlib-install/tree/v3.11.21) (2019-09-04)

#### Merged Pull Requests
- Update product names to match new marketing names [#283](https://github.com/chef/mixlib-install/pull/283) ([tas50](https://github.com/tas50))
- Fix typo in README [#288](https://github.com/chef/mixlib-install/pull/288) ([gaelik](https://github.com/gaelik))
- Add omnibus-gcc and fix up tests [#291](https://github.com/chef/mixlib-install/pull/291) ([scotthain](https://github.com/scotthain))

## [v3.11.18](https://github.com/chef/mixlib-install/tree/v3.11.18) (2019-05-09)

#### Merged Pull Requests
- Bug when concatenating http_proxy environment variables [#278](https://github.com/chef/mixlib-install/pull/278) ([tyler-ball](https://github.com/tyler-ball))
- Update github templates and cutover to the Chef Foundation team [#280](https://github.com/chef/mixlib-install/pull/280) ([tas50](https://github.com/tas50))
- Set the proxy environment variables using bourne shell syntax [#281](https://github.com/chef/mixlib-install/pull/281) ([MarkGibbons](https://github.com/MarkGibbons))
- Use a grep command compatible with solaris 10 and older greps [#282](https://github.com/chef/mixlib-install/pull/282) ([MarkGibbons](https://github.com/MarkGibbons))
- Remove the PR template and use the org level template [#284](https://github.com/chef/mixlib-install/pull/284) ([tas50](https://github.com/tas50))
- Add project owner information to the readme [#285](https://github.com/chef/mixlib-install/pull/285) ([tas50](https://github.com/tas50))

## [v3.11.12](https://github.com/chef/mixlib-install/tree/v3.11.12) (2019-04-15)

#### Merged Pull Requests
- Add support for armv7l [#279](https://github.com/chef/mixlib-install/pull/279) ([LocutusOfBorg](https://github.com/LocutusOfBorg))

## [v3.11.11](https://github.com/chef/mixlib-install/tree/v3.11.11) (2019-02-06)

#### Merged Pull Requests
- Rename suse platform to opensuseleap [#268](https://github.com/chef/mixlib-install/pull/268) ([tas50](https://github.com/tas50))
- Update install scripts to not mention Omnibus [#271](https://github.com/chef/mixlib-install/pull/271) ([tas50](https://github.com/tas50))
- Cleanup testing and expeditor configs to match other Chef projects [#265](https://github.com/chef/mixlib-install/pull/265) ([tas50](https://github.com/tas50))
- Properly return Windows Desktop SKUs on projects with 64-bit only builds [#276](https://github.com/chef/mixlib-install/pull/276) ([schisamo](https://github.com/schisamo))

## [v3.11.5](https://github.com/chef/mixlib-install/tree/v3.11.5) (2018-08-08)

#### Merged Pull Requests
- update amazon platform mapping to support Versions 1, 2, and 2 RCs [#264](https://github.com/chef/mixlib-install/pull/264) ([wrightp](https://github.com/wrightp))

## [v3.11.4](https://github.com/chef/mixlib-install/tree/v3.11.4) (2018-08-01)

#### Merged Pull Requests
- Add github issue and PR templates [#266](https://github.com/chef/mixlib-install/pull/266) ([tas50](https://github.com/tas50))

## [v3.11.3](https://github.com/chef/mixlib-install/tree/v3.11.3) (2018-07-25)

#### Merged Pull Requests
- Test on Ruby head in Travis [#263](https://github.com/chef/mixlib-install/pull/263) ([tas50](https://github.com/tas50))

## [v3.11.2](https://github.com/chef/mixlib-install/tree/v3.11.2) (2018-07-09)

#### Merged Pull Requests
- Switch to VERSION_ID to detect the Amazon Linux Release [#262](https://github.com/chef/mixlib-install/pull/262) ([tas50](https://github.com/tas50))

## [v3.11.1](https://github.com/chef/mixlib-install/tree/v3.11.1) (2018-07-06)

#### Merged Pull Requests
- Fix Amazon 2 detection [#261](https://github.com/chef/mixlib-install/pull/261) ([tas50](https://github.com/tas50))
- Bump version to 3.11.0 [#260](https://github.com/chef/mixlib-install/pull/260) ([tas50](https://github.com/tas50))

## [v3.10.3](https://github.com/chef/mixlib-install/tree/v3.10.3) (2018-07-03)

#### Merged Pull Requests
- Move remap logic from install.sh to omnitruck [#259](https://github.com/chef/mixlib-install/pull/259) ([tas50](https://github.com/tas50))

## [v3.10.2](https://github.com/chef/mixlib-install/tree/v3.10.2) (2018-07-02)

#### Merged Pull Requests
- Don&#39;t remap fedora in platform_detection.sh [#257](https://github.com/chef/mixlib-install/pull/257) ([tas50](https://github.com/tas50))

## [v3.10.1](https://github.com/chef/mixlib-install/tree/v3.10.1) (2018-07-02)

#### Merged Pull Requests
- Switch to trusty packages and test on the latest Ruby releases in Travis [#258](https://github.com/chef/mixlib-install/pull/258) ([tas50](https://github.com/tas50))

## [v3.10.0](https://github.com/chef/mixlib-install/tree/v3.10.0) (2018-05-10)

#### Merged Pull Requests
- Adding TLS negotiation support for older versions of .NET [#254](https://github.com/chef/mixlib-install/pull/254) ([andy-dufour](https://github.com/andy-dufour))

## [v3.9.4](https://github.com/chef/mixlib-install/tree/v3.9.4) (2018-05-10)

#### Merged Pull Requests
- Updates for recent product changes [#255](https://github.com/chef/mixlib-install/pull/255) ([schisamo](https://github.com/schisamo))

## [v3.9.3](https://github.com/chef/mixlib-install/tree/v3.9.3) (2018-02-01)

#### Merged Pull Requests
- Update filespec to be more selective in its inclusivity [#250](https://github.com/chef/mixlib-install/pull/250) ([scotthain](https://github.com/scotthain))

## [v3.9.2](https://github.com/chef/mixlib-install/tree/v3.9.2) (2018-02-01)

#### Merged Pull Requests
- Update expeditor config to allow gem builds [#249](https://github.com/chef/mixlib-install/pull/249) ([scotthain](https://github.com/scotthain))

## [v3.9.1](https://github.com/chef/mixlib-install/tree/v3.9.1) (2018-01-31)

#### Merged Pull Requests
- Remove windows 7, 8, and 8.1 as they are no longer supported [#248](https://github.com/chef/mixlib-install/pull/248) ([scotthain](https://github.com/scotthain))

## [v3.9.0](https://github.com/chef/mixlib-install/tree/v3.9.0) (2017-12-20)

#### Merged Pull Requests
- add amazon linux 2.0 platform detection support [#246](https://github.com/chef/mixlib-install/pull/246) ([wrightp](https://github.com/wrightp))

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