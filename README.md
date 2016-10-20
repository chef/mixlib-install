[![Build Status](https://travis-ci.org/chef/mixlib-install.svg?branch=master)](https://travis-ci.org/chef/mixlib-install)

# Mixlib::Install

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

### Get URL for specific platform and package version
```ruby
require 'mixlib/install'

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

### Collecting Software Dependencies and License Content
Collecting software dependencies and license content for ArtifactInfo instances
requires additional requests to the repository server. By default, collection is disabled.
To return data for instance methods `software_dependencies` and `license_content`, the `include_metadata` option must be enabled.

```
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

## Development
VCR is a tool that helps cache and replay http responses. When these responses change or when you add more tests you might need to update cached responses. Check out [spec_helper.rb](https://github.com/chef/mixlib-install/blob/master/spec/spec_helper.rb) for instructions on how to do this.

## Contributing

1. Fork it ( https://github.com/[my-github-username]/mixlib-install/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
