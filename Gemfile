source "https://rubygems.org"

gemspec

group :docs do
  gem "github-markup"
  gem "redcarpet"
  gem "yard"
end

group :test do
  gem "rake"
  gem "rspec"
  gem "vcr"
  gem "webmock", "~> 3.4"
  gem "aruba", "~> 0.14"
  gem "cucumber", "~> 1.3.20"
  gem "climate_control"
end

if RUBY_VERSION =~ /^2/
  group :chefstyle do
    gem "chefstyle", "~> 0.13.3"
  end
end

group :debug do
  gem "pry"
  gem "pry-byebug"
  gem "pry-stack_explorer"
  gem "rb-readline"
end
