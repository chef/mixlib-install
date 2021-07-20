source "https://rubygems.org"

gemspec

gem "chef-utils", "= 16.6.14" if RUBY_VERSION < "2.6.0"

group :test do
  gem "rake"
  gem "rspec"
  gem "vcr"
  gem "webrick"
  gem "webmock", "~> 3.4"
  gem "aruba", "~> 0.14"
  gem "cucumber", "~> 7.0.0"
  if RUBY_VERSION < "2.5.0"
    gem "climate_control", "= 0.1.0"
  else
    gem "climate_control", "~> 1.0"
  end
end

# use old chefstyle to support TargetRubyVersion of 1.9
group :chefstyle do
  gem "chefstyle", "~> 0.4.0"
end

group :debug do
  gem "pry"
  gem "pry-byebug"
  gem "rb-readline"
end
