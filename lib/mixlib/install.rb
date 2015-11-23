#
# Author:: Thom May (<thom@chef.io>)
# Author:: Patrick Wright (<patrick@chef.io>)
# Copyright:: Copyright (c) 2015 Chef, Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require "mixlib/versioning"

require "mixlib/install/backend"
require "mixlib/install/options"
require "mixlib/install/generator"

module Mixlib
  class Install

    attr_reader :options

    def initialize(options = {})
      @options = Options.new(options)
    end

    #
    # Fetch artifact metadata information
    #
    # @return [ArtifactInfo] fetched artifact data
    #
    def artifact_info
      Backend.info(options)
    end

    #
    # Returns an install script for the given options
    #
    # @return [String] script for installing with given options
    #
    def install_command
      Generator.install_command(options)
    end

    #
    # Returns the base installation directory for the given options
    #
    # @return [String] the installation directory for the project
    #
    def root
      # TODO: Support root as "$env:systemdrive\\opscode\\chef" when on windows.
      # This only works for chef and chefdk but they are the only projects
      # we are supporting as of now.
      "/opt/#{options.product_name}"
    end

    #
    # Returns the current version of the installed product.
    # Returns nil if the product is not installed.
    #
    def current_version
      # Note that this logic does not work for products other than
      # chef & chefdk since version-manifest is created under the
      # install directory which can be different than the product name (e.g.
      # chef-server -> /opt/opscode). But this is OK for now since
      # chef & chefdk are the only supported products for now.
      version_manifest_file = "/opt/#{options.product_name}/version-manifest.json"
      if File.exist? version_manifest_file
        JSON.parse(File.read(version_manifest_file))["build_version"]
      end
    end

    #
    # Returns true if an upgradable version is available, false otherwise.
    #
    def upgrade_available?
      return false if current_version.nil?

      available_ver = Mixlib::Versioning.parse(artifact_info.first.version)
      current_ver = Mixlib::Versioning.parse(current_version)
      (available_ver > current_ver)
    end
  end
end
