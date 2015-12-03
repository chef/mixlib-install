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

module Mixlib
  class Install
    class Generator
      class PowerShell
        attr_reader :options

        def initialize(options)
          @options = options
        end

        def install_command
          install_project_module = []
          install_project_module << get_script(:helpers)
          if options.for_artifactory?
            raise "not implemented yet"
            # install_project_module << get_script(:get_project_metadata_for_artifactory)
          else
            install_project_module << get_script(:get_project_metadata)
          end
          install_project_module << get_script(:install_project)

          install_command = []
          install_command << ps1_modularize(install_project_module.join("\n"), "Omnitruck")
          install_command << render_command
          install_command.join("\n\n")
        end

        def ps1_modularize(module_body, module_name)
          ps1_module = []
          ps1_module << "new-module -name #{module_name} -scriptblock {"
          ps1_module << module_body
          ps1_module << "}"
          ps1_module.join("\n")
        end

        def render_command
          <<EOS
install -project #{options.product_name} \
-version #{options.product_version} \
-channel #{options.channel}
EOS
        end

        def get_script(name)
          File.read(File.join(File.dirname(__FILE__), "powershell/scripts/#{name}.ps1"))
        end
      end
    end
  end
end
