# -*- encoding: utf-8 -*-
# stub: mixlib-versioning 1.1.0 ruby lib

Gem::Specification.new do |s|
  s.name = "mixlib-versioning".freeze
  s.version = "1.1.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Seth Chisamore".freeze, "Christopher Maier".freeze]
  s.date = "2015-06-04"
  s.description = "General purpose Ruby library that allows you to parse, compare and manipulate version strings in multiple formats.".freeze
  s.email = ["schisamo@chef.io".freeze, "cm@chef.io".freeze]
  s.homepage = "https://github.com/chef/mixlib-versioning".freeze
  s.licenses = ["Apache 2.0".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 1.9".freeze)
  s.rubygems_version = "2.6.6".freeze
  s.summary = "General purpose Ruby library that allows you to parse, compare and manipulate version strings in multiple formats.".freeze

  s.installed_by_version = "2.6.6" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<rubocop>.freeze, ["= 0.31.0"])
      s.add_development_dependency(%q<rspec>.freeze, ["~> 2.14"])
      s.add_development_dependency(%q<bundler>.freeze, [">= 0"])
      s.add_development_dependency(%q<rake>.freeze, [">= 0"])
    else
      s.add_dependency(%q<rubocop>.freeze, ["= 0.31.0"])
      s.add_dependency(%q<rspec>.freeze, ["~> 2.14"])
      s.add_dependency(%q<bundler>.freeze, [">= 0"])
      s.add_dependency(%q<rake>.freeze, [">= 0"])
    end
  else
    s.add_dependency(%q<rubocop>.freeze, ["= 0.31.0"])
    s.add_dependency(%q<rspec>.freeze, ["~> 2.14"])
    s.add_dependency(%q<bundler>.freeze, [">= 0"])
    s.add_dependency(%q<rake>.freeze, [">= 0"])
  end
end
