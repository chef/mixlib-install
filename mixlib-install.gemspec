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

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.executables   = ["mixlib-install"]
  spec.require_paths = ["lib"]

  spec.add_dependency "mixlib-shellout"
  spec.add_dependency "mixlib-versioning"
  spec.add_dependency "thor"

  spec.add_development_dependency "aruba"
  spec.add_development_dependency "bundler"
  spec.add_development_dependency "chefstyle"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rb-readline"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "simplecov"
  spec.add_development_dependency "vcr"
  spec.add_development_dependency "webmock"
end
