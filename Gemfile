source "https://rubygems.org"

gemspec

group :test do
  gem "climate_control", "~> 1.2"
  gem "rake", ">= 13.0"
  gem "rspec", "~> 3.13"
  gem "vcr", ">= 6.1"
  gem "webmock", "~> 3.26"
  gem "webrick"
  gem "simplecov", require: false

  # Former default gems that became bundled gems and are required without
  # being declared as dependencies by the gems that use them
  gem "base64" if RUBY_VERSION >= "3.4.0"
  gem "benchmark" if RUBY_VERSION >= "4.0.0"
end

group :chefstyle do
  gem "chefstyle", "~> 0.12.0" # Minimum version that will run without errors on Ruby 3.4
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
