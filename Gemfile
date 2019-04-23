source "https://rubygems.org"

gemspec

group :docs do
  gem "yard"
  gem "redcarpet"
  gem "github-markup"
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
    gem "chefstyle", "~> 0.4.0"
  end
end

group :development do
  gem "pry"
  gem "pry-byebug"
  gem "pry-stack_explorer"
  gem "rb-readline"
end

instance_eval(ENV["GEMFILE_MOD"]) if ENV["GEMFILE_MOD"]

# If you want to load debugging tools into the bundle exec sandbox,
# add these additional dependencies into Gemfile.local
eval_gemfile(__FILE__ + ".local") if File.exist?(__FILE__ + ".local")
