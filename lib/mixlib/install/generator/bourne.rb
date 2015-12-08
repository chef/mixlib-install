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

require "erb"
require "ostruct"
require "mixlib/install/backend/omnitruck"

module Mixlib
  class Install
    class Generator
      class Bourne
        attr_reader :options

        def initialize(options)
          @options = options
        end

        def self.install_sh(context)
          install_command = []
          install_command << get_script(:helpers)
          install_command << get_script(:script_cli_parameters)
          install_command << get_script(:platform_detection)
          install_command << get_script(:fetch_metadata, context)
          install_command << get_script(:fetch_package)
          install_command << get_script(:install_package)
          install_command.join("\n\n")
        end

        def install_command
          install_command = []
          install_command << get_script(:helpers)
          install_command << render_variables
          install_command << get_script(:platform_detection)
          if options.for_artifactory?
            install_command << artifactory_urls
          else
            install_command << get_script(:fetch_metadata)
          end
          install_command << get_script(:fetch_package)
          install_command << get_script(:install_package)

          install_command.join("\n\n")
        end

        def render_variables
          <<EOS
project=#{options.product_name}
version=#{options.product_version}
channel=#{options.channel}
EOS
        end

        def artifactory_urls
          raise "not implemented yet"
        end

        #
        # Gets the contents of the given script.
        #
        def self.get_script(name, context = {})
          script_path = File.join(File.dirname(__FILE__), "bourne/scripts/#{name}.sh")

          # If there is an erb template we render it, otherwise we just read
          # and returnt the contents of the script
          if File.exist? "#{script_path}.erb"
            # Default values to use incase they are not set in the context
            context[:base_url] ||= Mixlib::Install::Backend::Omnitruck::OMNITRUCK_ENDPOINT

            context_object = OpenStruct.new(context).instance_eval { binding }
            ERB.new(File.read("#{script_path}.erb")).result(context_object)
          else
            File.read(script_path)
          end
        end

        def get_script(name)
          self.class.get_script(name)
        end
      end
    end
  end
end
