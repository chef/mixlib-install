#
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

module Mixlib
  class Install
    class ArtifactInfo

      ATTRIBUTES = %w{
        architecture
        license
        license_content
        md5
        platform
        platform_version
        product_description
        product_name
        sha1
        sha256
        software_dependencies
        url
        version
      }.freeze

      # Attribute name paired with its instance variable name, computed once at
      # load time so that #initialize and #to_hash allocate no intermediate
      # Strings or Symbols per call.
      ATTRIBUTE_IVARS = ATTRIBUTES.map { |a| [a.to_sym, :"@#{a}"] }.freeze

      # Dynamically create readers
      ATTRIBUTES.each { |attribute| attr_reader attribute.to_sym }

      def initialize(data)
        # Create an instance variable for each attribute
        ATTRIBUTE_IVARS.each do |name, ivar|
          instance_variable_set(ivar, data[name])
        end
      end

      def self.from_json(json, platform_info)
        require "json" unless defined?(JSON)
        ArtifactInfo.new(JSON.parse(json, symbolize_names: true).merge(platform_info))
      end

      def self.from_metadata_map(json)
        require "json" unless defined?(JSON)
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
        # Create a Hash of the instance data
        ATTRIBUTE_IVARS.each_with_object({}) do |(name, ivar), hash|
          hash[name] = instance_variable_get(ivar)
        end
      end

      def clone_with(data)
        ArtifactInfo.new(to_hash.merge(data))
      end

      def appx_artifact?
        url.end_with?(".appx")
      end
    end
  end
end
