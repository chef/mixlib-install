require "aruba/rspec"

Aruba.configure do |config|
  config.exit_timeout                          = 120
  config.io_wait_timeout                       = 2
  config.activate_announcer_on_command_failure = [:stderr, :stdout, :command]
end

RSpec.configure do |config|
  config.filter_run focus: true
  config.run_all_when_everything_filtered = true

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
