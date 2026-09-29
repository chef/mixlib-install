# Coverage has to start before any library code is loaded, or the files
# required below are never instrumented.
unless ENV["COVERAGE"] == "false"
  begin
    require "simplecov"
    # `rake unit` and `rake functional` run separately; give each its own
    # result so SimpleCov merges them instead of the last one winning.
    suite = ARGV.join(" ")[%r{spec/(unit|functional)}, 1]
    SimpleCov.start do
      command_name "RSpec #{suite || "all"}"
      add_filter "/spec/"
      add_group "Backend", "lib/mixlib/install/backend"
      add_group "Generator", "lib/mixlib/install/generator"
      enable_coverage :branch
      # Guard against coverage regressions in the hermetic unit suite
      minimum_coverage line: 95 if suite == "unit"
    end
  rescue LoadError
    warn "simplecov is not installed; skipping coverage"
  end
end

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require "mixlib/install"
require "vcr"
require "webmock/rspec"
require "webrick"
require "webrick/httpproxy"
require "climate_control"

VERSION_MANIFEST_DIR = File.expand_path("support/version_manifests", __dir__)
EXTRA_FILE = File.expand_path("fixtures/extra/extra_distributions.rb", __dir__)

Dir[File.expand_path("support/**/*.rb", __dir__)].sort.each { |f| require f }

RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.syntax = :expect
    c.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    # Stubbing a method that does not exist on the real object is an error
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
  if ENV["CI"]
    # A stray :focus silently skips the rest of the suite; never allow it in CI
    config.before(:example, :focus) do |ex|
      raise "Focused example left in the suite: #{ex.location}"
    end
  else
    config.filter_run_when_matching :focus
  end
  config.example_status_persistence_file_path = "spec/examples.txt"
  config.disable_monkey_patching!
  config.warnings = false
  config.default_formatter = "doc" if config.files_to_run.one?
  config.order = :random
  Kernel.srand config.seed

  # Examples tagged :vcr replay recorded HTTP interactions. Functional specs
  # exercise the real CLI against the real services. Everything else must not
  # touch the network: WebMock raises on any unstubbed request.
  config.around(:each) do |ex|
    if ex.metadata[:type] == :functional
      WebMock.allow_net_connect!
      VCR.turned_off { ex.run }
    elsif ex.metadata.key?(:vcr)
      ex.run
    else
      WebMock.disable_net_connect!(allow_localhost: true)
      VCR.turned_off { ex.run }
    end
  end

  config.define_derived_metadata(file_path: %r{/spec/functional/}) do |metadata|
    metadata[:type] = :functional
  end
end

#
# VCR configuration
#
# Cassettes live under spec/fixtures/vcr and are named after the example.
#
# By default a missing interaction is an error (record: :none), so the suite
# never talks to the network by accident. To record or refresh cassettes:
#
#   VCR_RECORD=new_episodes bundle exec rspec spec/unit/...   # add new calls
#   VCR_RECORD=all bundle exec rspec spec/unit/...            # re-record
#
VCR.configure do |config|
  config.cassette_library_dir = File.expand_path("fixtures/vcr", __dir__)
  config.hook_into :webmock
  config.configure_rspec_metadata!
  config.default_cassette_options = { record: (ENV["VCR_RECORD"] || "none").to_sym }
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
