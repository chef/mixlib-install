# Mixlib::Install

[![Gem Version](https://badge.fury.io/rb/mixlib-install.svg)](https://badge.fury.io/rb/mixlib-install)

**Umbrella Project**: [Chef Foundation](https://github.com/chef/chef-oss-practices/blob/master/projects/chef-foundation.md)

**Project State**: [Active](https://github.com/chef/chef-oss-practices/blob/master/repo-management/repo-states.md#active)

**Issues [Response Time Maximum](https://github.com/chef/chef-oss-practices/blob/master/repo-management/repo-states.md)**: 14 days

**Pull Request [Response Time Maximum](https://github.com/chef/chef-oss-practices/blob/master/repo-management/repo-states.md)**: 14 days

## Supports

- Ruby 2.6+
- Chef 11.6.2+ chef-client upgrades

Ruby support is based on the oldest Ruby that is included in an OS
that Chef Infra Client currently supports, not including those in
extended release.

You can see a table of supported platforms and Ruby versions in [this Google Sheet](https://docs.google.com/spreadsheets/d/1G6BCcR2d6CRBG1uTpEtikdwB17jIY00lLQazlSf1fEM/edit?usp=sharing).

As of last update of this README, the data is:

| Ruby version | Supported Until | OSes | Total OS versions |
| -- | -- | -- | -- |
| 2.6 | ? | 1 | 3 |
| 3.0 | 2027-05-31 | 3 | 3 |
| 3.1 | 2026-06-10 | 1 | 1 |
| 3.2 | 2029-06-30 | 3 | 4 |
| 3.3 | 2031-11-01 | 4 | 4 |
| 3.4 | 2031-07-31 | 2 | 4 |

NOTE: 2.6 has no EOL date because MacOS doesn't have published EOL dates and all currently released MacOS versions ship with Ruby 2.6.

However, see the Google Sheet for the latest information.

## Command Line Usage

Install the gem:

```bash
gem install mixlib-install
```

Download latest stable chef for current platform:

```bash
mixlib-install download chef
```

Run `mixlib-install help` for additional commands and options.

## API Usage

### Load mixlib-install

```ruby
require 'mixlib/install'
```

### Get URL for specific platform and package version

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
# => #<Mixlib::Install::ArtifactInfo>

artifact.url
# => "https://packages.chef.io/files/stable/chef/16.13.16/mac_os_x/10.15/chef-16.13.16-1.x86_64.dmg"
```

### Get list of artifacts for all platforms given a package version

```ruby
options = {
  channel: :current,
  product_name: 'chef'
}
# product_version: :latest is the default

artifacts = Mixlib::Install.new(options).artifact_info
# => [#<Mixlib::Install::ArtifactInfo>, ...]

artifacts.first.url
# => => "https://packages.chef.io/files/stable/chef/16.13.16/mac_os_x/10.15/chef-16.13.16-1.x86_64.dmg"
```

### Get latest artifacts for a partial version

```ruby
options = {
  channel: :current,
  product_name: 'chef',
  product_version: '12.14'
}

artifacts = Mixlib::Install.new(options).artifact_info
# => [#<Mixlib::Install::ArtifactInfo>]

artifacts.first.version
# => "12.14.89"
```

### Get latest artifact for a partial version

```ruby
options = {
  channel: :current,
  product_name: 'chef',
  product_version: '16',
  platform: 'mac_os_x',
  platform_version: '10.15',
  architecture: 'x86_64'
}

artifact = Mixlib::Install.new(options).artifact_info
# => #<Mixlib::Install::ArtifactInfo>

artifact.version
# => "12.19.36"
```

### Detect platform information

```ruby
options = {
  channel: :current,
  product_name: 'chef',
  product_version: :latest
}

artifact = Mixlib::Install.new(options).detect_platform

artifact.platform # => "mac_os_x"
artifact.platform_version # => "10.10"
```

### Use an artifact released for an earlier version of the platform

```ruby
options = {
  channel: :current,
  product_name: 'chef',
  product_version: :latest,
  platform: 'ubuntu',
  platform_version: '15.04',
  architecture: 'x86_64',
  platform_version_compatibility_mode: true
}

artifact = Mixlib::Install.new(options).artifact_info

artifact.platform # => "ubuntu"
artifact.platform_version # => "14.04"
```

`platform_version_compatibility_mode` will automatically be enabled if platform options are not specified.

If running on Ubuntu 15.04...

```ruby
options = {
  channel: :current,
  product_name: 'chef',
}

artifact = Mixlib::Install.new(options).artifact_info

artifact.platform # => "ubuntu"
artifact.platform_version # => "14.04"
```

### List the available versions for a product and channel

#### Instance method

```ruby
options = {
  channel: :stable,
  product_name: 'chef',
}

Mixlib::Install.new(options).available_versions

# => ["12.13.3", "12.13.7"]
```

#### Class method

```ruby
Mixlib::Install.available_versions("chef", "stable")

# => ["12.13.3", "12.13.7"]
```

### Download an artifact

Download a specific artifact to a configurable location. All platform options (platform, platform_version, architecture) are required  in order to filter a single artifact.

```ruby
# detect platform and download to the operating system’s temporary file path
Mixlib::Install.new(product_name: "chefdk", channel: :stable).detect_platform.download_artifact(Dir.tmpdir)
# => "/tmp/chefdk-2.3.4-1.deb"

# specify platform options and download to current directory
Mixlib::Install.new(product_name: "chefdk", channel: :stable, platform: "ubuntu", platform_version: "14.04", architecture: "x86_64").download_artifact
# => "~/chefdk-2.3.4-1.deb"
```

### User-Agent Request Headers

By default, all requests made by `mixlib-install` will include a `User-Agent` request header as `mixlib-install/<version>`.
Additional `User-Agent` request headers can be added by setting the `user_agent_headers` option.
When you want to identify a product using mixlib-install as a dependency we recommend the format `product/version`.

```ruby
options = {
  channel: :stable,
  product_name: 'chef',
  user_agent_headers: ["my_product/1.2.3", "somethingelse"],
}
```

### Collecting Software Dependencies and License Content

Collecting software dependencies and license content for ArtifactInfo instances
requires additional requests to the repository server. By default, collection is disabled.
To return data for instance methods `software_dependencies` and `license_content`, the `include_metadata` option must be enabled.

```ruby
options = {
  channel: :current,
  product_name: 'chef',
  product_version: :latest,
  platform: 'mac_os_x',
  platform_version: '10.15',
  architecture: 'x86_64',
  include_metadata: true,
}

artifact = Mixlib::Install.new(options).artifact_info

artifact.license_content.class
# => String
artifact.software_dependencies.class
# => Hash

# By default, the instance methods return nil
```

### Install Scripts

mixlib-install generates the bootstrap installation scripts known as install.sh and install.ps1. The associated install script will be returned when calling `#install_command` on the Mixlib::Install instance.

Mixlib::Install instantiation option `install_command_options` can accept variables (bourne) or parameters (powershell) to modify the behavior of the install scripts.

Some of the more common options include:

`download_url_override`: Use the provided URL instead of fetching the metadata URL from Chef Software Inc's software distribution systems.
`checksum`: SHA256 value associated to the directed file for the download_url_override option. This setting is optional. Not setting this will download the file even if a cached file is detected.
`install_strategy`: Set to "once" to have the script exit if the product being installed is detected.

```ruby
options = {
  product_name: 'chef',
  install_command_options: {
    download_url_override: "https://file/path",
    checksum: "OPTIONAL",
    install_strategy: "once",
  }
}

Mixlib::Install.new(options).install_command
```

#### Proxies

The API uses Ruby's OpenURI module to load proxy environment variables (`http_proxy`, `https_proxy`, `ftp_proxy`, `no_proxy`).

When `install.sh` and `install.ps1` are executed as standalone scripts the will rely on environment variables to configure proxy settings. The install scripts will not configure proxy settings by default.

In order to customize the proxy environment variables for generated install scripts they must be set by the `install_command_options` option. Setting these options will override session environment variables.

Bourne install script (`install.sh`) supports `http_proxy`, `https_proxy`, `ftp_proxy`, and `no_proxy` passed as keys to `install_command_options`.

Powershell install script (`install.ps1`) supports `http_proxy` passed as a key to `install_command_options`.

### Extending for other products

Create a ruby file in your application and use the product DSL like this (see [product.rb](lib/mixlib/install/product.rb) for available properties):

```ruby
product "cinc" do
  product_name "Cinc Infra Client"
  package_name "cinc-client"
  api_url "https://packages.cinc.sh"
end
```

Then set an environment variable to load them like this on linux:

`export EXTRA_PRODUCTS_FILE=/path/to/your/file.rb`

Calls to mixlib-install now allow to target your new product, assuming the api_url match pacakges api for `/<channel>/<product>/versions` and `/<channel>/<product>/<version>/artifacts` endpoints.

## Licensed API Usage (Commercial and Trial)

Mixlib::Install supports both commercial and trial API endpoints for licensed Chef products. These APIs require a valid license ID and have specific restrictions.

### Trial API

The trial API is designed for evaluation purposes and has the following restrictions:

- **Endpoint**: `https://chefdownload-trial.chef.io`
- **License ID Format**: Must start with `free-` or `trial-`
- **Channel Restriction**: Only `stable` channel is supported
- **Version Restriction**: Only `latest` version is supported

When using a trial license ID, mixlib-install will **automatically** default to `stable` channel and `latest` version, displaying warnings if other values are provided:

```ruby
options = {
  product_name: 'chef',
  channel: :current,          # Will be changed to :stable with warning
  product_version: '18.5.0',  # Will be changed to :latest with warning
  license_id: 'free-trial-abc-123'
}

mi = Mixlib::Install.new(options)
# WARNING: Trial API only supports 'stable' channel. Changing from 'current' to 'stable'.
# WARNING: Trial API only supports 'latest' version. Changing from '18.5.0' to 'latest'.

mi.options.channel         # => :stable
mi.options.product_version # => :latest
```

### Commercial API

The commercial API provides full access to all channels and versions:

- **Endpoint**: `https://chefdownload-commercial.chef.io`
- **License ID Format**: Any valid commercial license ID (not starting with `free-` or `trial-`)
- **Channel Restriction**: None - all channels supported (`stable`, `current`, `unstable`)
- **Version Restriction**: None - all versions supported

```ruby
options = {
  product_name: 'chef',
  channel: :current,
  product_version: '18.5.0',
  license_id: 'commercial-license-key-123'
}

mi = Mixlib::Install.new(options)
# No warnings or defaults applied
mi.options.channel         # => :current
mi.options.product_version # => '18.5.0'
```

### Chef-ICE Product

The `chef-ice` product requires additional parameters (`m`, `p`, `pm`) and works with both commercial and trial APIs:

```ruby
options = {
  product_name: 'chef-ice',
  channel: :stable,
  product_version: :latest,
  platform: 'ubuntu',
  platform_version: '20.04',
  architecture: 'x86_64',
  license_id: 'free-trial-abc-123'  # Trial API
}

artifact = Mixlib::Install.new(options).artifact_info
artifact.url
# => "https://chefdownload-trial.chef.io/stable/chef-ice/download?v=19.1.151&license_id=free-trial-abc-123&m=x86_64&p=linux&pm=deb"
```

### Static Script Methods

The static methods `Mixlib::Install.install_sh()` and `Mixlib::Install.install_ps1()` also enforce trial API defaults:

```ruby
# Trial API defaults applied to generated script
script = Mixlib::Install.install_sh(
  license_id: 'free-trial-xyz',
  channel: :current,     # Will be changed to :stable with warning
  version: '18.0.0'      # Will be changed to :latest with warning
)
# WARNING: Trial API only supports 'stable' channel. Changing from 'current' to 'stable'.
# WARNING: Trial API only supports 'latest' version. Changing from '18.0.0' to 'latest'.
```

### License ID Detection

You can check if a license ID is for trial or commercial API:

```ruby
require 'mixlib/install/dist'

Mixlib::Install::Dist.trial_license?('free-trial-123')      # => true
Mixlib::Install::Dist.trial_license?('trial-abc-456')       # => true
Mixlib::Install::Dist.trial_license?('commercial-xyz')      # => false

Mixlib::Install::Dist.commercial_license?('commercial-xyz') # => true
Mixlib::Install::Dist.commercial_license?('free-trial-123') # => false
```

## Development

VCR is a tool that helps cache and replay http responses. When these responses change or when you add more tests you might need to update cached responses. Check out [spec_helper.rb](https://github.com/chef/mixlib-install/blob/master/spec/spec_helper.rb) for instructions on how to do this.

## Contributing

1. Fork it ( <https://github.com/[my-github-username]/mixlib-install/fork> )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
