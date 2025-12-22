# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "mixlib/install/version"

Gem::Specification.new do |spec|
  spec.name          = "mixlib-install"
  spec.version       = Mixlib::Install::VERSION
  spec.authors       = ["Thom May", "Patrick Wright"]
  spec.email         = ["thom@chef.io", "patrick@chef.io"]
  spec.license       = "Apache-2.0"

  spec.summary       = "A library for interacting with Chef Software Inc's software distribution systems."
  spec.homepage      = "https://github.com/chef/mixlib-install"

  spec.files         = %w{LICENSE Gemfile Rakefile} + Dir.glob("*.gemspec") + Dir.glob("{bin,lib,support}/**/*")
  spec.executables   = ["mixlib-install"]
  spec.require_paths = ["lib"]

  spec.add_dependency "mixlib-shellout"
  spec.add_dependency "mixlib-versioning"

  # OpenSSL version requirements based on Ruby version for CRL check issue fix
  # Ruby 3.4.x requires openssl gem >= 3.3.1
  # Ruby 3.3.x requires openssl gem >= 3.2.2
  # Ruby 3.2.x requires openssl gem >= 3.1.2
  if RUBY_VERSION >= "3.4.0"
    spec.add_dependency "openssl", ">= 3.3.1", "< 4.0"
  elsif RUBY_VERSION >= "3.3.0"
    spec.add_dependency "openssl", ">= 3.2.2", "< 4.0"
  elsif RUBY_VERSION >= "3.2.0"
    spec.add_dependency "openssl", ">= 3.1.2", "< 4.0"
  else
    spec.add_dependency "openssl", ">= 3.0", "< 4.0"
  end

  spec.add_dependency "thor"
end
