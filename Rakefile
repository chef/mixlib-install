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

desc "Render product matrix documentation"
task "matrix" do
  require "mixlib/install/product"

  doc_file = File.join(File.dirname(__FILE__), "PRODUCT_MATRIX.md")
  puts "Updating doc file at: #{doc_file}"

  File.open(doc_file, "w+") do |f|
    f.puts("| Product | Product Key  | Package Name |")
    f.puts("| ------- | ------------ | ------------ |")
    PRODUCT_MATRIX.products.each do |p_key|
      product = PRODUCT_MATRIX.lookup(p_key)
      f.puts("| #{product.product_name} | #{p_key} | #{product.package_name} |")
    end
    f.puts("")
    f.puts("Do not modify this file manually. It is automatically rendered via a rake task.")
  end
end
