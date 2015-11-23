$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)

VERSION_MANIFEST_DIR = File.expand_path("../support/version_manifests", __FILE__)

RSpec.configure do |conf|
  conf.filter_run focus: true
  conf.filter_run_excluding unstable: true
  conf.run_all_when_everything_filtered = true

  conf.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
