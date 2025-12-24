source "https://rubygems.org"

gemspec

gem "chef-utils", "= 16.6.14" if RUBY_VERSION < "2.6.0"
gem "mixlib-shellout", "< 3.3.9" if RUBY_VERSION < "3.0.0"

group :test do
  gem "contracts", "~> 0.16.0" # this entry can go away when ruby < 3 support is gone
  gem "rake"
  gem "rspec"
  gem "webrick"
  gem "webmock", "~> 3.4"
  if RUBY_VERSION < "2.6.0"
    gem "mixlib-shellout", "= 3.2.5"
    gem "public_suffix", "<= 5.1.1"
    gem "vcr", "= 6.0.0"
  elsif RUBY_VERSION < "3.0.0"
    gem "public_suffix", "<= 5.1.1"
  elsif RUBY_VERSION < "3.2.0"
    gem "public_suffix", "< 7.0.0"
  else
    gem "climate_control"
    gem "vcr"
  end
end

group :chefstyle do
  gem "chefstyle"
end

group :debug do
  gem "pry"
  gem "pry-byebug"
  if RUBY_VERSION < "2.7.0"
    gem "byebug", "< 12.0"
    gem "pry-byebug", "< 3.10.0"
  elsif RUBY_VERSION < "3.1.0"
    gem "byebug", "< 12.0"
  end
  gem "rb-readline"
end
