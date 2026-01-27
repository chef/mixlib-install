# Copilot Instructions for Mixlib::Install

## Project Overview
Mixlib::Install is a library for interacting with Chef Software Inc's software distribution systems. It provides APIs and command-line tools to download Chef products and generate installation scripts for various platforms.

**Primary Goal**: Support the widest range of Ruby versions possible to ensure compatibility across diverse Chef environments.

**Recent Major Changes** (v3.13.0 - v3.15.0):
- Added commercial and trial API support for licensed Chef products (PR #408, #416)
- Added chef-ice product with package_manager parameter support (PR #417)
- Refactored install directory constants to support both Omnibus and Habitat paths
  - Renamed `WINDOWS_INSTALL_DIR` → `OMNIBUS_WINDOWS_INSTALL_DIR`, `LINUX_INSTALL_DIR` → `OMNIBUS_LINUX_INSTALL_DIR`
  - Added `HABITAT_WINDOWS_INSTALL_DIR` and `HABITAT_LINUX_INSTALL_DIR` for chef-ice support
  - Updated all code paths to conditionally use Habitat directories for chef-ice product
- Added `list-products` CLI subcommand (PR #413)
- Added license_id parameter to install script endpoints (PR #416)
- Implemented trial API automatic defaults (stable channel, latest version only)
- Added Habitat package path detection to generated scripts (PR #407)
- Migrated CI from Buildkite to GitHub Actions (PR #411)

## Ruby Version Support Strategy

### Supported Ruby Versions
- **Minimum**: Ruby 2.6+
- **Target Range**: Ruby 2.6 through Ruby 3.4+
- **Testing Focus**: Maintain backward compatibility with Ruby 2.6+ while supporting latest Ruby releases

### Critical Compatibility Rules

1. **Avoid Modern Ruby Syntax**
   - NO numbered parameters `_1, _2` (Ruby 2.7+)
   - NO pattern matching (Ruby 2.7+)
   - NO endless methods (Ruby 3.0+)
   - Use Ruby 2.6-compatible syntax as the baseline

1. **Dependency Version Constraints**
   - Always use version-conditional dependency constraints in gemspec
   - Follow the existing pattern for Ruby version-specific dependencies (see `openssl` gem constraints in gemspec)
   - Consider backward compatibility when adding new dependencies
   - Check Gemfile for Ruby version-specific gem constraints before adding dependencies

1. **Standard Library Compatibility**
   - Be cautious with stdlib changes across Ruby versions
   - Test with methods available in Ruby 2.6
   - Avoid relying on gems that dropped support for Ruby 2.6+
   - Ruby 2.6 features that are safe to use:
     - Safe navigation operator (`&.`)
     - Squiggly heredoc (`<<~`)
     - `dig` method on Hash and Array
     - `grep_v` on Enumerable
     - Frozen string literal comment
     - Endless ranges: `(1..)`
     - `Enumerable#chain`
     - `Kernel#then`

## Code Style & Conventions

### RuboCop Configuration
- TargetRubyVersion: 2.6 (set in `.rubocop.yml`)
- Note: RuboCop targets 2.6 to match the minimum supported Ruby version
- Uses `chefstyle` gem version ~> 0.4.0
- Run style checks: `bundle exec rake style`

### Code Formatting
- **Indentation**: 2 spaces (defined in `.editorconfig`)
- **Line Endings**: Unix-style LF
- **Charset**: UTF-8
- **Trailing Whitespace**: Remove (trim_trailing_whitespace: true)
- **Final Newline**: Always include

### File Headers
All Ruby files should include the Apache 2.0 license header:
```ruby
#
# Author:: [Author Name] (<email@chef.io>)
# Copyright:: Copyright (c) [year] Chef Software, Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# ...
```

## Architecture & Structure

### Core Components

1. **Mixlib::Install** (`lib/mixlib/install.rb`)
   - Main entry point for the library
   - Provides `artifact_info`, `available_versions`, `install_command`, `download_artifact` methods
   - Delegates to Backend for API interactions

1. **Options** (`lib/mixlib/install/options.rb`)
   - Validates and normalizes user input
   - Supports EXTRA_PRODUCTS_FILE environment variable for custom products
   - Key options: channel, product_name, product_version, platform, platform_version, architecture, license_id
   - **license_id**: Enables commercial/trial API access for licensed Chef products
   - **Trial API Enforcement**: Automatically defaults channel to :stable and product_version to :latest when trial license detected
   - Uses `enforce_trial_api_defaults!` method during initialization to apply restrictions
   - Emits warnings to stderr when defaults are applied

1. **Product Matrix** (`lib/mixlib/install/product_matrix.rb`)
   - DSL for defining product metadata
   - Extensible via EXTRA_PRODUCTS_FILE
   - Run `bundle exec rake matrix` to update PRODUCT_MATRIX.md after changes

1. **Backend** (`lib/mixlib/install/backend/`)
   - Package Router backend for Chef's package API
   - Handles API communication with packages.chef.io

1. **Generators** (`lib/mixlib/install/generator/`)
   - Bourne shell (install.sh) generator with Content-Disposition header support
   - PowerShell (install.ps1) generator with JSON API response parsing
   - Supports proxy configuration, download_url_override, and license_id
   - **Commercial/Trial API Support**: When license_id is provided, uses specialized download endpoints
     - Trial API: `https://chefdownload-trial.chef.io` (for license IDs starting with `free-` or `trial-`)
     - Commercial API: `https://chefdownload-commercial.chef.io` (for other license IDs)
     - Returns JSON responses instead of text format
     - Uses Content-Disposition headers for filename extraction
     - Implements temp file download approach with multiple filename extraction methods

1. **Artifact Info** (`lib/mixlib/install/artifact_info.rb`)
   - Represents package metadata
   - Includes platform, version, URL, checksum, license info

### Supported Architectures
- aarch64, armv7l, i386, powerpc, ppc64, ppc64le, s390x, sparc, universal, x86_64

### Supported Channels
- :stable, :current, :unstable

## Testing

### Test Structure
- **Unit Tests**: `spec/unit/**/*_spec.rb`
- **Functional Tests**: `spec/functional/**/*_spec.rb`
- **Acceptance Tests**: `acceptance/**/*`

### Running Tests
```bash
bundle exec rake unit        # Unit tests only
bundle exec rake functional  # Functional tests only
bundle exec rake             # All tests (default)
```

### VCR for HTTP Mocking
- Uses VCR gem for recording/replaying HTTP interactions
- Cassettes stored in `spec/support/`
- To update cassettes, see instructions in `spec/spec_helper.rb`
- Functional tests disable VCR to test live interactions

### Gemspec vs Gemfile Dependencies
**Gemspec** (`mixlib-install.gemspec`):
- Runtime dependencies only
- Minimal dependencies: mixlib-shellout, mixlib-versioning, thor
- No version constraints in latest version (dependencies have their own compatibility handling)

**Gemfile**:
- Development and test dependencies
- Ruby version-specific constraints for test tools
- Includes chefstyle for linting (~> 0.4.0)
- VCR for HTTP mocking in tests

### Ruby Version-Specific Test Dependencies
The Gemfile contains careful version constraints for test dependencies based on RUBY_VERSION:
- Ruby < 2.6: Specific version pins for chef-utils, climate_control, mixlib-shellout, vcr
- Ruby 2.6-2.7: Different constraint ranges
- Ruby 2.7+: Loosened constraints
- Ruby 3.2+: Minimal constraints

When adding test dependencies, follow this pattern.

## Development Guidelines

### Adding New Features

1. **Product Addition**
   - Update `lib/mixlib/install/product_matrix.rb` with DSL definition
   - Run `bundle exec rake matrix` to update documentation
   - Add tests in `spec/unit/mixlib/install/product_spec.rb`

1. **Platform Support**
   - Update `lib/mixlib/install/options.rb` SUPPORTED_ARCHITECTURES if needed
   - Add platform detection logic in `lib/mixlib/install/util.rb`
   - Update install script generators if platform-specific logic needed

1. **API Changes**
   - Maintain backward compatibility
   - Add deprecation warnings before removing features
   - Update README.md with examples
   - Add/update tests

### Version Management
- Version defined in `lib/mixlib/install/version.rb`
- Follow semantic versioning
- Expeditor handles automated version bumps via labels:
  - "Expeditor: Bump Version Minor"
  - "Expeditor: Bump Version Major"

### Dependency Management

#### Adding Dependencies to Gemspec
1. Consider minimum Ruby version compatibility
1. Use version constraints with Ruby version conditionals if needed
1. Example pattern (from gemspec):
```ruby
if RUBY_VERSION < "2.7.0"
  spec.add_dependency "openssl", ">= 3.1.2", "< 3.2.0"
elsif RUBY_VERSION < "3.3.0"
  spec.add_dependency "openssl", ">= 3.1.2"
# ... etc
end
```

#### Adding Test Dependencies to Gemfile
- Group dependencies by Ruby version ranges
- Pin versions for older Ruby (< 2.6) to ensure compatibility
- Test locally with multiple Ruby versions if possible

### OpenSSL Dependency Notes
The gemspec includes special handling for the openssl gem due to CRL checking issues:
- Different version constraints based on Ruby version
- This pattern should be followed for other security-critical dependencies

## CLI Tool

### Command: mixlib-install
- Executable: `bin/mixlib-install`
- Entry point: `lib/mixlib/install/cli.rb`
- Uses Thor for CLI framework
- Run `mixlib-install help` for available commands

### Common Commands
```bash
mixlib-install download chef              # Download latest stable chef
mixlib-install list-products              # List all available products (added in v3.14.0)
mixlib-install help                       # Show all commands
```

### Available Subcommands
- `download` - Download a Chef Software product
- `list-products` - Display all available products from the product matrix
- `list-versions` - List available versions for a product
- `help` - Display help information

## Platform Version Compatibility Mode

The library includes sophisticated platform version compatibility logic:
- Automatically maps to earlier platform versions when exact match not available
- Example: Ubuntu 15.04 → Ubuntu 14.04 compatibility
- Controlled by `platform_version_compatibility_mode` option

## Install Script Generation

### Bourne Shell (install.sh)
- Supports: http_proxy, https_proxy, ftp_proxy, no_proxy
- Platform detection for Linux/Unix systems
- Generated via `lib/mixlib/install/generator/bourne.rb`
- **Content-Disposition Support**: When `license_id` is provided:
  - Downloads to temp file: `chef-download-temp.$$`
  - Extracts filename from HTTP response headers (3 methods):
    1. Content-Disposition header: `attachment; filename="..."`
    1. Location redirect header: Extract from redirect URL
    1. URL pattern matching: Search for `.rpm|.deb|.pkg|.msi|.dmg` patterns
  - Fallback: Constructs filename from platform metadata if extraction fails
  - Renames temp file to extracted/constructed filename
  - Works with all download methods: wget, curl, fetch, perl, python

### PowerShell (install.ps1)
- Supports: http_proxy
- Windows platform support
- TLS negotiation for older .NET versions
- Generated via `lib/mixlib/install/generator/powershell.rb`
- **JSON API Response**: When `license_id` is provided:
  - Parses JSON responses with `ConvertFrom-Json`
  - Extracts `url` and `sha256` from JSON object
  - Automatically routes to trial or commercial API based on license_id prefix

### Script Options
- `download_url_override`: Direct URL instead of API lookup
- `checksum`: SHA256 for verification
- `install_strategy`: "once" to skip if already installed
- `license_id`: License ID for commercial/trial API access (format: `free-*`, `trial-*`, or standard license ID)

## API Usage Patterns

### Basic Usage
```ruby
options = {
  channel: :current,
  product_name: 'chef',
  product_version: :latest,
  platform: 'mac_os_x',
  platform_version: '10.15',
  architecture: 'x86_64'
}
artifact = Mixlib::Install.new(options).artifact_info
```

### Proxy Configuration
Relies on OpenURI environment variables:
- http_proxy, https_proxy, ftp_proxy, no_proxy

## Product Extension System

Users can extend with custom products via EXTRA_PRODUCTS_FILE environment variable:
```ruby
# custom_products.rb
product "cinc" do
  product_name "Cinc Infra Client"
  package_name "cinc-client"
  api_url "https://packages.cinc.sh"
end
```

When implementing features, ensure this extensibility is maintained.

## GitHub Workflows & CI

- Uses Expeditor for release automation
- Verify pipeline in `.expeditor/verify.pipeline.yml`
- Linux tests: `.expeditor/run_linux_tests.sh`
- Windows tests: `.expeditor/run_windows_tests.ps1`

## Commercial and Trial API Integration

### Overview
Mixlib::Install supports Chef's commercial and trial licensing APIs, which provide authenticated access to Chef products for licensed customers.

### API Endpoints
- **Trial API**: `https://chefdownload-trial.chef.io`
  - Used when `license_id` starts with `free-` or `trial-`
  - Returns JSON responses with download URLs
  - **Restrictions**: Only `stable` channel and `latest` version supported
  - Defaults are automatically enforced with warnings
- **Commercial API**: `https://chefdownload-commercial.chef.io`
  - Used for standard license IDs
  - Returns JSON responses with download URLs
  - No restrictions on channels or versions
- **Traditional Omnitruck**: `https://omnitruck.chef.io`
  - Used when no `license_id` is provided
  - Returns text-based metadata responses

### Response Format Differences
- **Commercial/Trial APIs**: JSON format
  ```json
  {
    "url": "https://...",
    "sha256": "abc123..."
  }
  ```
- **Omnitruck API**: Text format
  ```
  url\thttp://...
  sha256\tabc123...
  ```

### License ID Detection Helper Methods (`lib/mixlib/install/dist.rb`)
```ruby
require 'mixlib/install/dist'

# Check if license_id indicates trial API usage
Mixlib::Install::Dist.trial_license?('free-trial-123')      # => true
Mixlib::Install::Dist.trial_license?('trial-abc-456')       # => true
Mixlib::Install::Dist.trial_license?('commercial-xyz')      # => false

# Check if license_id indicates commercial API usage
Mixlib::Install::Dist.commercial_license?('commercial-xyz') # => true
Mixlib::Install::Dist.commercial_license?('free-trial-123') # => false
```

**Trial License Detection Logic**:
- Returns `true` if license_id starts with `free-` or `trial-`
- Returns `false` for nil, empty string, or other prefixes

**Commercial License Detection Logic**:
- Returns `true` if license_id is present and NOT a trial license
- Returns `false` for nil, empty string, or trial licenses

### Content-Disposition Header Handling
Commercial and trial APIs return endpoint URLs that use HTTP Content-Disposition headers to specify the actual filename, rather than including the filename in the URL path.

**Implementation Details**:
1. **Detection**: `use_content_disposition="true"` when `license_id` is present
1. **Download Strategy**: Use temp file with process ID suffix: `chef-download-temp.$$`
1. **Filename Extraction** (3 methods, attempted in order):
   - Parse `Content-Disposition` header: `filename="chef-18.8.54-1.el9.x86_64.rpm"`
   - Parse `Location` redirect header: Extract filename from redirect URL
   - Pattern matching: Search stderr output for `.rpm|.deb|.pkg|.msi|.dmg` extensions
1. **Fallback Construction**: Build filename from platform metadata if extraction fails
1. **File Rename**: Move temp file to final location with extracted/constructed filename

**Cross-Platform Compatibility**: This approach works with all download methods:
- `wget` (with `--content-disposition` flag as secondary approach)
- `curl` (with `-O -J` flags as secondary approach)
- `fetch` (FreeBSD)
- `perl` (LWP::Simple)
- `python` (urllib2)

### Testing Commercial/Trial API Features
When adding or modifying commercial/trial API functionality:
1. Test with `license_id` starting with `free-` (trial API)
1. Test with `license_id` starting with `trial-` (trial API)
1. Test with standard license ID format (commercial API)
1. Verify JSON parsing in both Bourne shell (sed) and PowerShell (ConvertFrom-Json)
1. Test filename extraction with various response header formats
1. Verify fallback filename construction for each platform type
1. Test chef-ice product with package_manager parameter
1. Verify platform normalization for chef-ice on all supported platforms
1. Test trial API automatic defaults enforcement (stable channel, latest version)

## Chef-ICE Product Support

The `chef-ice` product (Chef Infra Client Enterprise, Chef 19+) requires special handling:

### Key Characteristics:
- **Product Name**: `chef-ice`
- **Package Name**: `chef-ice`
- **Minimum Version**: Chef 19.x
- **API Compatibility**: Works with both commercial and trial APIs
- **URL Parameters**: Uses `m`, `p`, `pm` instead of standard `p`, `pv`, `m` format
- **Install Directories**: Uses Habitat package paths instead of Omnibus paths

### Install Directory Constants (`lib/mixlib/install/dist.rb`):

Chef products use different install directory structures depending on whether they're packaged with Omnibus or Habitat:

**Omnibus Products** (chef, chefdk, etc.):
- Windows: `$env:systemdrive\opscode\{product}`
- Linux: `/opt/{product}`
- Constants: `OMNIBUS_WINDOWS_INSTALL_DIR`, `OMNIBUS_LINUX_INSTALL_DIR`

**Habitat Products** (chef-ice):
- Windows: `$env:systemdrive\hab\pkgs\chef\chef-infra-client\*\*`
- Linux: `/hab/pkgs/chef/chef-infra-client/*/*`
- Constants: `HABITAT_WINDOWS_INSTALL_DIR`, `HABITAT_LINUX_INSTALL_DIR`

**Implementation Details**:
- `OMNIBUS_WINDOWS_INSTALL_DIR = "opscode"` - Traditional Chef install base directory for Windows
- `OMNIBUS_LINUX_INSTALL_DIR = "/opt"` - Traditional Chef install base directory for Linux
- `HABITAT_WINDOWS_INSTALL_DIR = "hab\\pkgs"` - Habitat package directory for Windows
- `HABITAT_LINUX_INSTALL_DIR = "/hab/pkgs"` - Habitat package directory for Linux

**Usage in Code**:
- `lib/mixlib/install.rb`: `root` and `current_version` methods check product name and use appropriate constants
- `lib/mixlib/install/script_generator.rb`: Sets `@root` based on product type after initialization
- `lib/mixlib/install/generator/base.rb`: Conditionally sets `context[:windows_dir]` for chef-ice

The wildcard paths (`*/*`) in Habitat directories allow matching any version/release combination of the package.

### URL Parameter Differences:
**Standard Products (chef, chef-backend, etc.)**:
```
?p={platform}&pv={platform_version}&m={machine}&v={version}&license_id={id}
```

**Chef-ICE Product**:
```
?v={version}&license_id={id}&m={machine}&p={normalized_platform}&pm={package_manager}
```

### Platform Normalization (`Util.normalize_platform_for_commercial`):
Chef-ICE uses generic platform categories:
- **linux**: el, centos, rhel, fedora, rocky, scientific, debian, ubuntu, linuxmint, raspbian, opensuse, sles, amazon
- **macos**: mac_os_x, macos
- **windows**: windows
- **unix**: freebsd, aix, solaris, smartos, omnios
- **Default**: linux (for unknown platforms)

### Package Manager Detection (`Util.determine_package_manager`):
Automatically determines package format based on platform:
- **rpm**: el, centos, rhel, fedora, amazon, rocky, opensuse, sles, scientific
- **deb**: debian, ubuntu, linuxmint, raspbian
- **dmg**: mac_os_x, macos
- **msi**: windows
- **tar**: solaris, smartos, freebsd, aix, omnios
- **Default**: tar (for unknown platforms)

### Implementation Locations:
- **Backend Logic**: `lib/mixlib/install/backend/package_router.rb` (lines 265-270)
- **Utility Functions**: `lib/mixlib/install/util.rb` (lines 182-224)
- **Shell Script**: `lib/mixlib/install/generator/bourne/scripts/fetch_metadata.sh`
- **PowerShell Script**: `lib/mixlib/install/generator/powershell/scripts/get_project_metadata.ps1`

### Example Usage:
```ruby
options = {
  product_name: 'chef-ice',
  channel: :stable,
  product_version: :latest,
  platform: 'ubuntu',
  platform_version: '20.04',
  architecture: 'x86_64',
  license_id: 'free-trial-abc-123'
}

artifact = Mixlib::Install.new(options).artifact_info
# URL: https://chefdownload-trial.chef.io/stable/chef-ice/download?v=19.1.151&license_id=free-trial-abc-123&m=x86_64&p=linux&pm=deb
```

## Common Pitfalls to Avoid

1. **Don't use Ruby 2.7+ features** - Always consider Ruby 2.6 compatibility
1. **Don't assume gem availability** - Check version constraints in Gemfile first
1. **Don't break the Product Matrix DSL** - It's critical for product definitions
1. **Don't skip `rake matrix`** - Must run after modifying product_matrix.rb
1. **Don't hardcode URLs** - Use product definitions and API lookups
1. **Don't ignore platform compatibility** - Test across platforms when possible
1. **Don't add dependencies without version constraints** - Especially for Ruby 2.6+ support
1. **Don't assume filename in URL** - Commercial/trial APIs use Content-Disposition headers
1. **Don't break temp file download approach** - Required for license_id support across all download methods
1. **Don't forget chef-ice special handling** - Different URL parameters and platform normalization
1. **Don't bypass trial API defaults** - Trial licenses must use stable channel and latest version

## Documentation Requirements

When making changes:
1. Update README.md with API examples if public interface changes
1. Update CHANGELOG.md (handled by Expeditor)
1. Run `rake matrix` if products changed
1. Add code comments for complex compatibility logic
1. Document Ruby version requirements for new features

## Performance Considerations

- Minimize external gem dependencies
- Cache HTTP responses appropriately (VCR in tests)
- Efficient platform detection (runs on every install)
- Keep install scripts small and fast

## Security Considerations

1. **Checksum Verification**: Always provide/verify SHA256 checksums
1. **HTTPS**: Use secure connections to packages.chef.io
1. **OpenSSL**: Maintain up-to-date openssl gem constraints (see gemspec)
1. **Proxy Support**: Respect proxy settings in secure environments
1. **License Content**: Handle license_content securely (may contain sensitive info)

## Release Process

1. Merge PR to main branch
1. Expeditor automatically bumps version (unless skip label)
1. Expeditor builds gem
1. Manual promotion triggers RubyGems publish
1. GitHub release created with version tag (v{{version}})

## Getting Help

- **Slack**: #chef-found-notify (Chef Software internal)
- **GitHub Issues**: Response time maximum 14 days
- **Pull Requests**: Response time maximum 14 days
- **Project State**: Active (see README.md)

## Quick Reference

### Key Files
- `lib/mixlib/install.rb` - Main entry point
- `lib/mixlib/install/options.rb` - Option validation
- `lib/mixlib/install/product_matrix.rb` - Product definitions
- `lib/mixlib/install/version.rb` - Version constant
- `mixlib-install.gemspec` - Gem specification with dependency constraints
- `Gemfile` - Development/test dependencies with Ruby version logic

### Key Commands
- `bundle exec rake` - Run all tests
- `bundle exec rake matrix` - Update product matrix docs
- `bundle exec rake style` - Run style checks
- `bundle exec rake console` - Interactive console with mixlib-install loaded

### Environment Variables
- `EXTRA_PRODUCTS_FILE` - Path to custom product definitions
- `http_proxy`, `https_proxy`, `ftp_proxy`, `no_proxy` - Proxy configuration

---

**Remember**: When in doubt about Ruby version compatibility, check the Gemfile and gemspec for version-specific patterns, and test with Ruby 2.6+ when possible. The goal is maximum compatibility (Ruby 2.6+) without sacrificing functionality.

### Ruby 2.6+ Feature Reference

#### Safe to Use (Ruby 2.6+)
- Safe navigation operator: `object&.method`
- Squiggly heredoc: `<<~TEXT`
- `Hash#dig`, `Array#dig`
- `Enumerable#grep_v`
- `Hash#fetch_values`
- `Hash#to_proc`
- Frozen string literal pragma: `# frozen_string_literal: true`
- Endless ranges: `(1..)` 
- `Enumerable#chain`
- `Kernel#then`
- `Integer#digits`
- `Comparable#clamp`
- `String#match?`, `Regexp#match?`
- Multiple assignment in conditionals
- `yield_self` / `then`
- `rescue` in blocks without `begin`

#### Avoid (Ruby 2.7+)
- Numbered parameters: `_1`, `_2`
- Pattern matching
- `Enumerable#filter_map`
- `Enumerable#tally`
- Method reference operator: `.:`
