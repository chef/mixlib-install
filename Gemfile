source "https://rubygems.org"

gemspec

group :test do
  gem "rake"
  gem "rspec"
  gem "webrick"
  gem "webmock", "~> 3.4"
  gem "contracts", "~> 0.16.0" # this entry can go away when ruby < 3 support is gone
  gem "climate_control", "~> 1.0"
  gem "vcr"
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
