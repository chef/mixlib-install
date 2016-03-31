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
      attr_reader :url
      attr_reader :md5
      attr_reader :sha256
      attr_reader :sha1
      attr_reader :version

      attr_reader :platform
      attr_reader :platform_version
      attr_reader :architecture

      def initialize(data)
        @url = data[:url]
        @md5 = data[:md5]
        @sha256 = data[:sha256]
        @sha1 = data[:sha1]
        @version = data[:version]
        @platform = data[:platform]
        @platform_version = data[:platform_version]
        @architecture = data[:architecture]
      end

      def self.from_json(json, platform_info)
        ArtifactInfo.new(JSON.parse(json, symbolize_names: true).merge(platform_info))
      end

      def self.from_metadata_map(json)
        artifacts = []

        JSON.parse(json, symbolize_names: true).each do |p, p_data|
          p_data.each do |pv, pv_data|
            pv_data.each do |m, metadata|
              artifacts << ArtifactInfo.new(metadata.merge(
                platform: p,
                platform_version: pv,
                architecture: m
              ))
            end
          end
        end

        artifacts
      end

      def to_hash
        {
          url: url,
          md5: md5,
          sha256: sha256,
          sha1: sha1,
          version: version,
          platform: platform,
          platform_version: platform_version,
          architecture: architecture,
        }
      end

      def clone_with(data)
        ArtifactInfo.new(self.to_hash.merge(data))
      end
    end
  end
end
