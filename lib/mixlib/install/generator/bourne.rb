#
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

require "mixlib/install/generator/base"

module Mixlib
  class Install
    class Generator
      class Bourne < Base
        def self.install_sh(context)
          install_command = []
          install_command << get_script("helpers.sh", context)
          install_command << get_script("script_cli_parameters.sh")
          install_command << get_script("platform_detection.sh")
          install_command << get_script("fetch_metadata.sh", context)
          install_command << get_script("fetch_package.sh")
          install_command << get_script("install_package.sh")
          install_command.join("\n\n")
        end

        def self.detect_platform_sh
          get_script("platform_detection.sh")
        end

        def self.script_base_path
          File.join(File.dirname(__FILE__), "bourne/scripts")
        end

        def install_command
          install_command = []
          install_command << get_script("helpers.sh", user_agent_headers: options.user_agent_headers)
          install_command << render_variables
          install_command << get_script("platform_detection.sh")
          install_command << get_script("fetch_metadata.sh")
          install_command << get_script("fetch_package.sh")
          install_command << get_script("install_package.sh")

          install_command.join("\n\n")
        end

        def render_variables
          vars = []
          vars << "project=#{options.product_name}"
          vars << "version=#{options.product_version}"
          vars << "channel=#{options.channel}"
          vars << "https_proxy=#{options.https_proxy}" if options.https_proxy
          vars << "http_proxy=#{options.http_proxy}" if options.http_proxy
          vars << install_command_vars if options.install_command_options

          vars.join("\n")
        end

        def install_command_vars
          options.install_command_options.map { |key, value| "#{key}='#{value}'" }.join("\n")
        end
      end
    end
  end
end
