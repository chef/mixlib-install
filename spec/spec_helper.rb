$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

RSpec.configure do |conf|
  conf.filter_run focus: true
  conf.run_all_when_everything_filtered = true

  conf.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
