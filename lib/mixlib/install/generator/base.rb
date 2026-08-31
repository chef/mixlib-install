#
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

require_relative "../util"
require_relative "../dist"

module Mixlib
  class Install
    class Generator
      class Base
        attr_reader :options

        def initialize(options)
          @options = options
        end

        #
        # Returns the base path where the script fragments are located for
        # the generator as a String.
        #
        def self.script_base_path
          raise "You must define a script_base_path for your Generator::Base class."
        end

        #
        # Gets the contents of the given script.
        #
        def self.get_script(name, context = {})
          script = cached_script(File.join(script_base_path, name))

          # A plain script fragment is cached as a String and returned as-is.
          # Anything else is a compiled template and needs rendering. Testing
          # for String rather than ERB avoids referencing the ERB constant
          # before `erb` has been loaded.
          return script.dup if script.is_a?(String)

          # `ostruct` is only needed to render a template, so it is loaded here
          # rather than at require time.
          require "ostruct" unless defined?(OpenStruct)

          # Default values to use incase they are not set in the context
          context[:project_name] ||= Mixlib::Install::Dist::PROJECT_NAME.freeze
          context[:default_product] ||= Mixlib::Install::Dist::DEFAULT_PRODUCT.freeze
          context[:bug_url] ||= Mixlib::Install::Dist::BUG_URL.freeze
          context[:support_url] ||= Mixlib::Install::Dist::SUPPORT_URL.freeze
          context[:resources_url] ||= Mixlib::Install::Dist::RESOURCES_URL.freeze
          context[:macos_dir] ||= Mixlib::Install::Dist::MACOS_VOLUME.freeze
          context[:windows_dir] ||= context[:default_product].casecmp("chef-ice") == 0 ? Mixlib::Install::Dist::HABITAT_WINDOWS_INSTALL_DIR.freeze : Mixlib::Install::Dist::OMNIBUS_WINDOWS_INSTALL_DIR.freeze
          context[:user_agent_string] = Util.user_agent_string(context[:user_agent_headers])

          context_object = OpenStruct.new(context).instance_eval { binding }
          script.result(context_object)
        end

        #
        # Reads a script fragment from disk, compiling it first if it is an erb
        # template. The fragments ship inside the gem and do not change while
        # the process is running, so each one is read -- and compiled -- only
        # once. Returns an ERB for templates and a String for plain scripts.
        #
        def self.cached_script(script_path)
          @script_cache ||= {}
          @script_cache[script_path] ||=
            if File.exist? "#{script_path}.erb"
              # `erb` is only needed to compile a template, so it is loaded
              # here rather than at require time.
              require "erb" unless defined?(ERB)
              ERB.new(File.read("#{script_path}.erb"))
            else
              File.read(script_path)
            end
        end

        def get_script(name, context = {})
          self.class.get_script(name, context)
        end
      end
    end
  end
end
