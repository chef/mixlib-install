[![Build Status](https://travis-ci.org/chef/mixlib-install.svg?branch=master)](https://travis-ci.org/chef/mixlib-install)

# Mixlib::Install

## Supports

- Ruby 1.9.3+
- Chef 11.6.2+ chef-client upgrades

## Command Line Usage
```
$ gem install mixlib-install
```

```
# Download latest stable chef for current platform
$ mixlib-install download chef
```

Run `$ mixlib-install help` for additional commands and options.

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
  platform_version: '10.9',
  architecture: 'x86_64'
}

artifact = Mixlib::Install.new(options).artifact_info
# => #<Mixlib::Install::ArtifactInfo>

artifact.url
# => "https://packages.chef.io/files/current/chef/12.14.90/mac_os_x/10.9/chef-12.14.90-1.dmg"
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
# => => "https://packages.chef.io/files/current/chef/12.14.90/mac_os_x/10.11/chef-12.14.90-1.dmg"
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
  product_version: '12',
  platform: 'mac_os_x',
  platform_version: '10.9',
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
  platform_version: '10.9',
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

## Development
VCR is a tool that helps cache and replay http responses. When these responses change or when you add more tests you might need to update cached responses. Check out [spec_helper.rb](https://github.com/chef/mixlib-install/blob/master/spec/spec_helper.rb) for instructions on how to do this.

## Contributing

1. Fork it ( https://github.com/[my-github-username]/mixlib-install/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
