# load lib path
$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)

require "aruba/rspec"
require "mixlib/install"
require "vcr"
require "webmock/rspec"
require "webrick"
require "webrick/httpproxy"
require "climate_control"

Aruba.configure do |config|
  config.exit_timeout                          = 120
  config.io_wait_timeout                       = 2
  config.activate_announcer_on_command_failure = [:stderr, :stdout, :command]
end

# load version manifest support path
VERSION_MANIFEST_DIR = File.expand_path("../support/version_manifests", __FILE__)
EXTRA_FILE = File.join(File.dirname(__FILE__), "/fixtures/extra/extra_distributions.rb")

RSpec.configure do |config|
  config.filter_run focus: true
  config.run_all_when_everything_filtered = true

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # Ensure VCR/WebMock are disabled for functional tests
  config.around(:each) do |ex|
    if ex.metadata.key?(:vcr)
      ex.run
    else
      WebMock.allow_net_connect!
      VCR.turned_off { ex.run }
    end
  end
end

begin
  require "simplecov"
  SimpleCov.start
rescue LoadError
  puts "install simplecov in Gemfile.local for coverage reports"
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
  # We use different set of casettes depending on the unified_backend feature
  config.cassette_library_dir = File.join(File.dirname(__FILE__), "fixtures/vcr")

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
  config.default_cassette_options = { :record => :new_episodes }
end

def with_modified_env(options, &block)
  ClimateControl.modify(options, &block)
end

# Run code block with an available proxy server
def with_proxy_server
  proxy = WEBrick::HTTPProxyServer.new Port: 8401, BindAddress: "127.0.0.1"
  Thread.new { proxy.start }

  yield
ensure
  proxy.shutdown
  sleep 0.5
end
