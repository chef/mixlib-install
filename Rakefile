require "bundler/gem_tasks"
require "rspec/core/rake_task"

task default: :ci

desc "Run specs"
RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = "spec/**/*_spec.rb"
end

begin
  require "chefstyle"
  require "rubocop/rake_task"
  RuboCop::RakeTask.new(:style) do |task|
    task.options += ["--display-cop-names", "--no-color"]
  end
rescue LoadError
  puts "chefstyle/rubocop is not available.  gem install chefstyle to do style checking."
end

desc "Run specs for unified_backend (artifactory)"
task :unified_backend do
  ENV["MIXLIB_INSTALL_UNIFIED_BACKEND"] = "true"
  ENV["ARTIFACTORY_ENDPOINT"] = "https://packages-acceptance.chef.io"
  Rake::Task["spec"].reenable
  Rake::Task["spec"].invoke
  ENV.delete "MIXLIB_INSTALL_UNIFIED_BACKEND"
  ENV.delete "ARTIFACTORY_ENDPOINT"
end

desc "Run all tests"
task test: [:style, :spec, :unified_backend]

desc "Run tests for Travis CI"
task ci: [:style, :spec, :unified_backend]

desc "Render product matrix documentation"
task "matrix" do
  require "mixlib/install/product"

  doc_file = File.join(File.dirname(__FILE__), "PRODUCT_MATRIX.md")
  puts "Updating doc file at: #{doc_file}"

  File.open(doc_file, "w+") do |f|
    f.puts("| Product | Product Key  |")
    f.puts("| ------- | ------------ |")
    PRODUCT_MATRIX.products.sort.each do |p_key|
      product = PRODUCT_MATRIX.lookup(p_key)
      f.puts("| #{product.product_name} | #{p_key} |")
    end
    f.puts("")
    f.puts("Do not modify this file manually. It is automatically rendered via a rake task.")
  end
end

task :console do
  require "irb"
  require "irb/completion"
  require "mixlib/install"
  ARGV.clear
  IRB.start
end
