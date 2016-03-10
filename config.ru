require "rubygems"
require "bundler"

Bundler.require

require_relative "spec/support/bintray_server"
run BintrayServer
