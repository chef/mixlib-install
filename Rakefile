require "bundler/gem_tasks"
require "rspec/core/rake_task"

task default: :test

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

desc "Run all tests"
task test: [:style, :spec]

desc "Run tests for Travis CI"
task ci: [:style, :spec]

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
