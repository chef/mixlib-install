#
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

module Mixlib
  class Install
    class ArtifactInfo
      attr_accessor :url
      attr_accessor :md5
      attr_accessor :sha256
      attr_accessor :version

      def initialize(data)
        @url = data[:url]
        @md5 = data[:md5]
        @sha256 = data[:sha256]
        @version = data[:version]
      end

      def self.from_json(json)
        ArtifactInfo.new(JSON.parse(json, symbolize_names: true))
      end

      def to_hash
        {
          url: url,
          md5: md5,
          sha256: sha256,
          version: version
        }
      end
    end
  end
end
