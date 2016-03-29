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

## Unstable channel
The `:unstable` channel is currently only available when connected to Chef's internal network.
Configure Artifactory access by setting the following environment variables:
```
export ARTIFACTORY_USERNAME='username'
export ARTIFACTORY_PASSWORD='password'
```

### Unstable channel specs
Some spec examples are tagged `:unstable` and can only run when connected to Chef's internal network.  These are excluded by default.  To run the `:unstable` tests run: `rake unstable`.

## Contributing

1. Fork it ( https://github.com/[my-github-username]/mixlib-install/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
