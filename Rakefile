require "bundler/gem_tasks"
require "finstyle"
require "rubocop/rake_task"
require "rspec/core/rake_task"

task default: :spec

desc "Run specs"
RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = "spec/**/*_spec.rb"
end

RuboCop::RakeTask.new do |task|
  task.options << "--display-cop-names"
end
