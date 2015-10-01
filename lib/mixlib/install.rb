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

require 'mixlib/install/artifact_info'

module Mixlib
  class Install
    attr_accessor :project_name

    attr_accessor :version

    attr_accessor :channel

    def initialize(project_name, version, channel)
      @project_name = project_name
      @version = version
      @channel = channel
    end

    #
    # Fetch artifact metadata information
    #
    # @return [ArtifactInfo] fetched artifact
    #
    def info
      ArtifactInfo.new
    end

    def install_command
    end
  end
end
