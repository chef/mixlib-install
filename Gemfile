source "https://rubygems.org"

gemspec

gem "chef-utils", "= 16.6.14" if RUBY_VERSION < "2.6.0"

group :test do
  gem "contracts", "~> 0.16.0" # this entry can go away when ruby < 3 support is gone
  gem "rake"
  gem "rspec"
  gem "webrick"
  gem "webmock", "~> 3.4"
  if RUBY_VERSION < "2.6.0"
    gem "climate_control", "= 0.1.0"
    gem "mixlib-shellout", "= 3.2.5"
    gem "public_suffix", "<= 5.1.1" # Dep of addressable which is a dep of webmock
    gem "vcr", "= 6.0.0"
  elsif RUBY_VERSION < "2.7.0"
    gem "climate_control", "~> 1.0"
    gem "mixlib-shellout", "< 3.3.9"
    gem "public_suffix", "<= 5.1.1" # Dep of addressable which is a dep of webmock
    gem "vcr", ">= 6.0.0", "< 6.2.0"
  elsif RUBY_VERSION < "3.0.0"
    gem "climate_control", "~> 1.0"
    gem "mixlib-shellout", "< 3.3.9"
    gem "public_suffix", "<= 5.1.1" # Dep of addressable which is a dep of webmock
    gem "vcr"
  elsif RUBY_VERSION < "3.2.0"
    gem "climate_control", "~> 1.0"
    gem "public_suffix", "< 7.0.0" # Dep of addressable which is a dep of webmock
    gem "vcr"
  elsif RUBY_VERSION < "3.3.0"
    gem "climate_control", "~> 1.0"
    gem "public_suffix", "< 7.0.0" # Dep of addressable which is a dep of webmock
    gem "vcr"
  elsif RUBY_VERSION >= "4.0.0"
    gem "base64"
    gem "benchmark"
    gem "climate_control", "~> 1.0"
    gem "ostruct"
    gem "racc"
    gem "vcr"
  elsif RUBY_VERSION >= "3.4.0"
    gem "base64"
    gem "climate_control", "~> 1.0"
    gem "racc"
    gem "vcr"
  elsif RUBY_VERSION >= "3.3.0"
    gem "climate_control", "~> 1.0"
    gem "racc"
    gem "vcr"
  else
    gem "climate_control", "~> 1.0"
    gem "vcr"
  end
end

group :chefstyle do
  gem "chefstyle", "~> 0.8.0"
end

group :debug do
  gem "pry"
  if RUBY_VERSION < "2.7.0"
    gem "byebug", "< 12.0" # Dep of pry-bybug
    gem "pry-byebug", "< 3.10.0"
  elsif RUBY_VERSION < "3.1.0"
    gem "byebug", "< 12.0" # Dep of pry-bybug
    gem "pry-byebug"
  else
    gem "pry-byebug"
  end
  gem "rb-readline"
end
