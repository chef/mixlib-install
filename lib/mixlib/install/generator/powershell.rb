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
      class PowerShell < Base
        def self.install_ps1(context)
          install_project_module = []
          install_project_module << get_script("helpers.ps1")
          install_project_module << get_script("get_project_metadata.ps1", context)
          install_project_module << get_script("install_project.ps1")

          install_command = []
          install_command << ps1_modularize(install_project_module.join("\n"), "Omnitruck")
          install_command.join("\n\n")
        end

        def self.detect_platform_ps1
          detect_platform_command = []
          detect_platform_command << get_script("helpers.ps1")
          detect_platform_command << get_script("platform_detection.ps1")
          detect_platform_command.join("\n\n")
        end

        def self.script_base_path
          File.join(File.dirname(__FILE__), "powershell/scripts")
        end

        def install_command
          install_project_module = []
          install_project_module << get_script("helpers.ps1")
          install_project_module << if options.for_artifactory?
                                      artifactory_urls
                                    else
                                      get_script("get_project_metadata.ps1")
                                    end
          install_project_module << get_script("install_project.ps1")

          install_command = []
          install_command << ps1_modularize(install_project_module.join("\n"), "Omnitruck")
          install_command << render_command
          install_command.join("\n\n")
        end

        def self.ps1_modularize(module_body, module_name)
          ps1_module = []
          ps1_module << "new-module -name #{module_name} -scriptblock {"
          ps1_module << module_body
          ps1_module << "}"
          ps1_module.join("\n")
        end

        def ps1_modularize(module_body, module_name)
          self.class.ps1_modularize(module_body, module_name)
        end

        def artifactory_urls
          get_script("get_project_metadata_for_artifactory.ps1",
                     artifacts: artifacts)
        end

        def artifacts
          @artifacts ||= Mixlib::Install::Backend::Artifactory.new(options).info
        end

        def product_version
          if options.for_artifactory?
            artifacts.first.version
          else
            options.product_version
          end
        end

        def render_command
          cmd = "install -project #{options.product_name}"
          cmd << " -version #{product_version}"
          cmd << " -channel #{options.channel}"
          cmd << " -architecture #{options.architecture}" if options.architecture
          cmd << "\n"
        end
      end
    end
  end
end
