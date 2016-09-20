# -*- encoding: utf-8 -*-
# stub: artifactory 2.5.0 ruby lib

Gem::Specification.new do |s|
  s.name = "artifactory".freeze
  s.version = "2.5.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Seth Vargo".freeze]
  s.date = "2016-09-15"
  s.description = "A Ruby client for Artifactory".freeze
  s.email = "sethvargo@gmail.com".freeze
  s.homepage = "https://github.com/opscode/artifactory-client".freeze
  s.licenses = ["Apache 2.0".freeze]
  s.rubygems_version = "2.6.6".freeze
  s.summary = "Artifactory is a simple, lightweight Ruby client for interacting with the Artifactory and Artifactory Pro APIs.".freeze

  s.installed_by_version = "2.6.6" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<bundler>.freeze, [">= 0"])
      s.add_development_dependency(%q<rake>.freeze, [">= 0"])
    else
      s.add_dependency(%q<bundler>.freeze, [">= 0"])
      s.add_dependency(%q<rake>.freeze, [">= 0"])
    end
  else
    s.add_dependency(%q<bundler>.freeze, [">= 0"])
    s.add_dependency(%q<rake>.freeze, [">= 0"])
  end
end
