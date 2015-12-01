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

  spec.summary       = "A mixin to help with omnitruck installs"
  spec.homepage      = "https://chef.io"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "artifactory", "~> 2.3.0"
  spec.add_dependency "mixlib-versioning", "~> 1.1.0"

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.3"
  spec.add_development_dependency "pry"
end
