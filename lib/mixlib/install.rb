#
# Author:: Thom May (<thom@chef.io>)
# Copyright:: Copyright (c) 2015 Opscode, Inc.
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

require "mixlib/install/util"

module Mixlib
  class Install
    attr_accessor :version

    attr_accessor :powershell

    attr_accessor :prerelease

    attr_accessor :nightlies

    attr_accessor :endpoint

    attr_accessor :root

    attr_accessor :use_sudo
    attr_accessor :sudo_command

    attr_accessor :http_proxy
    attr_accessor :https_proxy

    attr_accessor :base_url

    def initialize(version, powershell = false, opts = {})
      @version = version
      @powershell = powershell
      @http_proxy = nil
      @https_proxy = nil
      @prerelease = false
      @nightly = false
      @endpoint = "metadata"
      @base_url = "https://www.chef.io/chef/install.sh"
      @use_sudo = true
      @sudo_command = "sudo -E"

      @root = if powershell
        "$env:systemdrive\\opscode\\chef"
      else
        "/opt/chef"
      end

      parse_opts(opts)
    end

    def install
      vars = if powershell
        install_command_vars_for_powershell
      else
        install_command_vars_for_bourne
      end
      shell_code_from_file(vars)
    end

    private

    # Generates the install command variables for Bourne shell-based
    # platforms.
    #
    # @return [String] shell variable lines
    # @api private
    def install_command_vars_for_bourne
      install_flags = %w[latest true].include?(version) ? "" : "-v #{version}"
      install_flags << " " << "-n" if nightlies
      install_flags << " " << "-p" if prerelease

      [
        shell_var("chef_omnibus_root", root),
        shell_var("chef_omnibus_url", base_url),
        shell_var("install_flags", install_flags.strip),
        shell_var("pretty_version", Util.pretty_version(version)),
        shell_var("sudo_sh", sudo("sh")),
        shell_var("version", version)
      ].join("\n")
    end

    # Generates the install command variables for PowerShell-based platforms.
    #
    # @param version [String] version string
    # @param metadata_url [String] The metadata URL for the Chef Omnitruck API server
    # @param omnibus_root [String] The base directory the project is installed to
    # @return [String] shell variable lines
    # @api private
    def install_command_vars_for_powershell
      [
        shell_var("chef_metadata_url", windows_metadata_url),
        shell_var("chef_omnibus_root", root),
        shell_var("msi", "$env:TEMP\\chef-#{version}.msi"),
        shell_var("pretty_version", Util.pretty_version(version)),
        shell_var("version", version)
      ].join("\n")
    end

    # rubocop:disable Metrics/CyclomaticComplexity
    def parse_opts(opts)
      opts.each do |opt, setting|
        case opt.to_s
        when "http_proxy"
          self.http_proxy = setting
        when "https_proxy"
          self.https_proxy = setting
        when "prerelease"
          self.prerelease = setting
        when "endpoint"
          self.endpoint = metadata_endpoint_from_project(setting)
        when "base"
          self.base_url = setting
        when "nightlies"
          self.nightlies = setting
        when "sudo_command"
          self.use_sudo = true
          self.sudo_command = setting
        end
      end
    end

    def shell_code_from_file(vars)
      fn = File.join(
        File.dirname(__FILE__),
        %w[.. .. support],
        "install_command"
      )
      Util.shell_code_from_file(vars, fn, powershell,
                                http_proxy: http_proxy, https_proxy: https_proxy)
    end

    # Builds a shell variable assignment string for the required shell type.
    #
    # @param name [String] variable name
    # @param value [String] variable value
    # @return [String] shell variable assignment
    # @api private
    def shell_var(name, value)
      Util.shell_var(name, value, powershell)
    end

    # @return the correct Chef Omnitruck API metadata endpoint, based on project
    def metadata_endpoint_from_project(project = nil)
      if project.nil? || project.downcase == "chef"
        "metadata"
      else
        "metadata-#{project.downcase}"
      end
    end

    def windows_metadata_url
      base = if base_url =~ %r{/install.sh$}
        "#{File.dirname(base_url)}"
      end

      url = "#{base}#{endpoint}"
      url << "?p=windows&m=x86_64&pv=2008r2" # same package for all versions
      url << "&v=#{version.to_s.downcase}"
      url << "&prerelease=true" if prerelease
      url << "&nightlies=true" if nightlies
      url
    end

    # Conditionally prefixes a command with a sudo command.
    #
    # @param command [String] command to be prefixed
    # @return [String] the command, conditionaly prefixed with sudo
    # @api private
    def sudo(script)
      use_sudo ? "#{sudo_command} #{script}" : script
    end
  end
end
