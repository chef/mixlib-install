# Mixlib::Install

## Usage

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
# => ArtifactInfo

artifact.url
# => "http://opscode-omnibus-packages-current.s3.amazonaws.com/mac_os_x/10.9/x86_64/chef-12.5.1%2B20151009083009-1.dmg"
```

### Get list of artifacts for all platforms given a package version
```ruby
options = {
  channel: :current,
  product_name: 'chef',
  product_version: :latest
}

artifacts = Mixlib::Install.new(options).artifact_info
# => Array<ArtifactInfo>

artifacts.first.url
# => "http://opscode-omnibus-packages-current.s3.amazonaws.com/mac_os_x/10.9/x86_64/chef-12.5.1%2B20151009083009-1.dmg"
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

## Unstable channel
The `:unstable` channel is currently only available when connected to Chef's internal network.

## Development
Since mixlib-install needs to interact with Bintray and Artifactory and since Artifactory instances are only available in Chef's network, this project uses [vcr](https://github.com/vcr/vcr).

VCR is a tool that helps cache and replay http responses. When these responses change or when you add more tests you might need to update cached responses. Check out [spec_helper.rb](https://github.com/chef/mixlib-install/blob/master/spec/spec_helper.rb) for instructions on how to do this.

## Contributing

1. Fork it ( https://github.com/[my-github-username]/mixlib-install/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
