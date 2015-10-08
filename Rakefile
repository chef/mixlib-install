require "bundler/gem_tasks"
require "finstyle"
require "rubocop/rake_task"
require "rspec/core/rake_task"

task default: :test

desc "Run specs"
RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = "spec/**/*_spec.rb"
end

desc "Run rubocop"
RuboCop::RakeTask.new do |task|
  task.options << "--display-cop-names"
end

desc "Run all tests"
task test: [:rubocop, :spec]
