source "https://rubygems.org"

gemspec

group :test, :development do
  gem "rake"
  gem "rspec"
  gem "vcr"
  gem "webmock", "~> 2.3.2"      # ruby 1.9.3
  gem "addressable", "~> 2.4.0"  # ruby 1.9.3
  gem "aruba", "~> 0.14"
  gem "cucumber", "~> 1.3.20"
  gem "climate_control"
end

if RUBY_VERSION =~ /^2/
  group :chefstyle do
    gem "chefstyle"
  end
end

instance_eval(ENV["GEMFILE_MOD"]) if ENV["GEMFILE_MOD"]

# If you want to load debugging tools into the bundle exec sandbox,
# add these additional dependencies into Gemfile.local
eval(IO.read(__FILE__ + ".local"), binding) if File.exist?(__FILE__ + ".local")
