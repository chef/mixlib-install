# Mixlib::Install

## Usage

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

artifact.to_hash
# => {
#      url: "http://opscode-omnibus-packages-current.s3.amazonaws.com/mac_os_x/10.9/x86_64/chef-12.5.1%2B20151009083009-1.dmg",
#      md5: "b1e39e6a8b1e38f734b2cdffc7774def",
#      sha256: "9f2acd34a0e7a608f21fdefc7cd39a6a4366ba65fe9970705cf2fb9e25eda1c5",
#      version: "12.5.1+20151009083009"
#    }

artifact.url
# => "http://opscode-omnibus-packages-current.s3.amazonaws.com/mac_os_x/10.9/x86_64/chef-12.5.1%2B20151009083009-1.dmg"
```

## Test
Some tests are tagged `:unstable` and can only run when connected to Chef's internal network.  These are excluded by default.  To run the `:unstable` tests run: `bundle exec rspec --tag unstable`.

## Contributing

1. Fork it ( https://github.com/[my-github-username]/mixlib-install/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
