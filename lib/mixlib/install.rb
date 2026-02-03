#
# Author:: Thom May (<thom@chef.io>)
# Author:: Patrick Wright (<patrick@chef.io>)
# Copyright:: Copyright (c) 2015-2018 Chef Software, Inc.
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
require "mixlib/shellout" unless defined?(Mixlib::ShellOut)

require_relative "install/backend"
require_relative "install/options"
require_relative "install/generator"
require_relative "install/generator/bourne"
require_relative "install/generator/powershell"
require_relative "install/dist"

module Mixlib
  class Install

    attr_reader :options

    def initialize(options = {})
      @options = Options.new(options)
    end

    #
    # Fetch artifact metadata information
    #
    # @return [Array<ArtifactInfo>] list of fetched artifact data for the configured
    # channel, product name, and product version.
    # @return [ArtifactInfo] fetched artifact data for the configured
    # channel, product name, product version and platform info
    def artifact_info
      Backend.info(options)
    end

    #
    # List available versions
    #
    # @return [Array<String>] list of available versions for the given
    # product_name and channel.
    def available_versions
      self.class.available_versions(options.product_name, options.channel)
    end

    #
    # List available versions
    #
    # @param [String] product name
    #
    # @param [String, Symbol] channel
    #
    # @return [Array<String>] list of available versions for the given
    # product_name and channel.
    def self.available_versions(product_name, channel)
      Backend.available_versions(
        Mixlib::Install::Options.new(
          product_name: product_name,
          channel: channel.to_sym
        )
      )
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
    # Download a single artifact
    #
    # @param [String] download directory. Default: Dir.pwd
    #
    # @return [String] file path of downloaded artifact
    #
    def download_artifact(directory = Dir.pwd)
      if options.platform.nil? || options.platform_version.nil? || options.architecture.nil?
        raise "Must provide platform options to download a specific artifact"
      end

      artifact = artifact_info

      FileUtils.mkdir_p directory

      # Handle the full URL including query string and redirects
      uri = URI.parse(artifact.url)
      filename = nil
      final_body = nil

      Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https") do |http|
        # Build the request path including query string
        request_path = uri.path
        request_path += "?#{uri.query}" if uri.query

        # Get the response, following redirects
        response = http.request_get(request_path)

        # Follow redirects
        redirect_limit = 5
        while response.is_a?(Net::HTTPRedirection) && redirect_limit > 0
          redirect_uri = URI.parse(response["location"])
          # Handle relative redirects
          redirect_uri = uri + redirect_uri if redirect_uri.relative?

          Net::HTTP.start(redirect_uri.host, redirect_uri.port, use_ssl: redirect_uri.scheme == "https") do |redirect_http|
            redirect_path = redirect_uri.path
            redirect_path += "?#{redirect_uri.query}" if redirect_uri.query
            response = redirect_http.request_get(redirect_path)

            # Try to get filename from Content-Disposition or final URL
            if response["content-disposition"]
              filename = response["content-disposition"][/filename="?([^"]+)"?/, 1]
            else
              filename = File.basename(redirect_uri.path)
            end
          end

          redirect_limit -= 1
        end

        final_body = response.body
      end

      # Use the extracted filename or fall back to basename of original URL
      filename ||= File.basename(uri.path)
      file = File.join(directory, filename)

      # Write the final response body to file
      File.open(file, "wb") do |io|
        io.write(final_body)
      end

      file
    end

    #
    # Returns the base installation directory for the given options
    #
    # @return [String] the installation directory for the project
    #
    def root
      # This only works for chef and chefdk but they are the only projects
      # we are supporting as of now.
      if options.for_ps1?
        "$env:systemdrive\\#{Mixlib::Install::Dist::OMNIBUS_WINDOWS_INSTALL_DIR}\\#{options.product_name}"
      else
        "#{Mixlib::Install::Dist::OMNIBUS_LINUX_INSTALL_DIR}/#{options.product_name}"
      end
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
      # chef & chefdk are the only supported products.
      version_manifest_file = if options.for_ps1?
                                "$env:systemdrive\\#{Mixlib::Install::Dist::OMNIBUS_WINDOWS_INSTALL_DIR}\\#{options.product_name}\\version-manifest.json"
                              else
                                "#{Mixlib::Install::Dist::OMNIBUS_LINUX_INSTALL_DIR}/#{options.product_name}/version-manifest.json"
                              end

      if File.exist? version_manifest_file
        JSON.parse(File.read(version_manifest_file))["build_version"]
      end
    end

    #
    # Returns true if an upgradable version is available, false otherwise.
    #
    def upgrade_available?
      return true if current_version.nil?

      artifact = artifact_info
      artifact = artifact.first if artifact.is_a? Array
      available_ver = Mixlib::Versioning.parse(artifact.version)
      current_ver = Mixlib::Versioning.parse(current_version)
      (available_ver > current_ver)
    end

    #
    # Automatically set the platform options
    #
    def detect_platform
      options.set_platform_info(self.class.detect_platform)
      self
    end

    #
    # Returns a Hash containing the platform info options
    #
    def self.detect_platform
      output = if Gem.win_platform?
                 # For Windows we write the detect platform script and execute the
                 # powershell.exe program with Mixlib::ShellOut
                 Dir.mktmpdir do |d|
                   File.open(File.join(d, "detect_platform.ps1"), "w+") do |f|
                     f.puts detect_platform_ps1
                   end

                   # An update to most Windows versions > 2008r2 now sets the execution policy
                   # to disallow unsigned powershell scripts. This changes it for just this
                   # powershell session, which allows this to run even if the execution policy
                   # is set higher.
                   Mixlib::ShellOut.new("powershell.exe -NoProfile -file #{File.join(d, "detect_platform.ps1")}", :env => { "PSExecutionPolicyPreference" => "Bypass" }).run_command
                 end
               else
                 Mixlib::ShellOut.new(detect_platform_sh).run_command
               end

      platform_info = output.stdout.split

      {
        platform: platform_info[0],
        platform_version: platform_info[1],
        architecture: platform_info[2],
      }
    end

    #
    # Returns the platform_detection.sh script
    #
    def self.detect_platform_sh
      Mixlib::Install::Generator::Bourne.detect_platform_sh
    end

    #
    # Returns the platform_detection.ps1 script
    #
    def self.detect_platform_ps1
      Mixlib::Install::Generator::PowerShell.detect_platform_ps1
    end

    #
    # Returns the install.sh script
    # Supported context parameters:
    # ------------------
    # base_url [String]
    #   url pointing to the omnitruck to be queried by the script.
    # license_id [String]
    #   license ID for commercial or trial API access.
    #   If license_id starts with 'free-' or 'trial-', trial API defaults are enforced.
    #
    def self.install_sh(context = {})
      # Apply trial API defaults if license_id indicates trial
      if context[:license_id] && Mixlib::Install::Dist.trial_license?(context[:license_id])
        # Warn and override if non-compliant values provided
        if context[:channel] && context[:channel].to_s != "stable"
          warn "WARNING: Trial API only supports 'stable' channel. Changing from '#{context[:channel]}' to 'stable'."
          context[:channel] = "stable"
        end

        if context[:version] && !["latest", nil].include?(context[:version].to_s)
          warn "WARNING: Trial API only supports 'latest' version. Changing from '#{context[:version]}' to 'latest'."
          context[:version] = "latest"
        end
      end

      Mixlib::Install::Generator::Bourne.install_sh(context)
    end

    #
    # Returns the install.ps1 script
    # Supported context parameters:
    # ------------------
    # base_url [String]
    #   url pointing to the omnitruck to be queried by the script.
    # license_id [String]
    #   license ID for commercial or trial API access.
    #   If license_id starts with 'free-' or 'trial-', trial API defaults are enforced.
    #
    def self.install_ps1(context = {})
      # Apply trial API defaults if license_id indicates trial
      if context[:license_id] && Mixlib::Install::Dist.trial_license?(context[:license_id])
        # Warn and override if non-compliant values provided
        if context[:channel] && context[:channel].to_s != "stable"
          warn "WARNING: Trial API only supports 'stable' channel. Changing from '#{context[:channel]}' to 'stable'."
          context[:channel] = "stable"
        end

        if context[:version] && !["latest", nil].include?(context[:version].to_s)
          warn "WARNING: Trial API only supports 'latest' version. Changing from '#{context[:version]}' to 'latest'."
          context[:version] = "latest"
        end
      end

      Mixlib::Install::Generator::PowerShell.install_ps1(context)
    end
  end
end
