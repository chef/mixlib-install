# load lib path
$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)

# load version manifest support path
VERSION_MANIFEST_DIR = File.expand_path("../support/version_manifests", __FILE__)

# load Bintray Sinatra server class
require_relative "support/bintray_server"
# Set local Bintray server endpoint
ENV["BINTRAY_ENDPOINT"] = "http://0.0.0.0:4567/api/v1"

RSpec.configure do |config|
  config.filter_run focus: true
  config.filter_run_excluding unstable: true
  config.run_all_when_everything_filtered = true

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

# Copied directly from
# https://github.com/ScrappyAcademy/rock_candy/blob/master/lib/rock_candy/helpers.rb
# Thank you, @cupakromer
def wrap_env(envs = {})
  original_envs = ENV.select { |k, _| envs.key? k }
  envs.each { |k, v| ENV[k] = v }

  yield
ensure
  envs.each { |k, _| ENV.delete k }
  original_envs.each { |k, v| ENV[k] = v }
end
