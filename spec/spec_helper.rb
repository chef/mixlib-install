# load lib path
$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)

require "webmock/rspec"
require "vcr"

# load version manifest support path
VERSION_MANIFEST_DIR = File.expand_path("../support/version_manifests", __FILE__)

RSpec.configure do |config|
  config.filter_run focus: true
  config.run_all_when_everything_filtered = true

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

#
# vcr configuration
#
# There are a couple cases where you will need to play with these settings:
# 1-) Updating cached responses:
#   Set 'default_cassette_options' to '{ :record => :all }' and run tests.
# 2-) If you add new tests or change the code to talk to different APIs,
#   you will see spec failures because we lock down the http connections by
#   disabling 'allow_http_connections_when_no_cassette'. In this case what
#   you need to do is:
#     Set 'default_cassette_options' to '{ :record => :new_episodes }' and
#       run tests.
#
VCR.configure do |config|
  # We use different set of casettes depending on the FULL_ARTIFACTORY flag
  config.cassette_library_dir = if ENV["FULL_ARTIFACTORY"].nil?
                                  File.join(File.dirname(__FILE__), "fixtures/vcr")
                                else
                                  File.join(File.dirname(__FILE__), "fixtures/vcr_full_artifactory")
                                end

  config.hook_into :webmock
  config.configure_rspec_metadata!
  # Options to be used during development:
  #
  # Enables vcr logger for debugging
  # config.debug_logger = File.open("vcr.log", 'w')
  #
  # Fails the specs if we get an http connection that we do not expect
  # config.allow_http_connections_when_no_cassette = true
  #
  # Re-records all http calls on top of existing fixtures
  # config.default_cassette_options = { :record => :all }
  #
  # Records new http calls without changing existing fixtures
  # config.default_cassette_options = { :record => :new_episodes }
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
