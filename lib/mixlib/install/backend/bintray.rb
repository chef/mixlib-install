#
# Author:: Patrick Wright (<patrick@chef.io>)
# Copyright:: Copyright (c) 2016 Chef, Inc.
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

require "mixlib/install/backend/base"

#
# Add method to Array class to support
# searching for substrings that match against
# the items in the Array
#
class Array
  def fuzzy_include?(search_value, regex_format = "%s")
    inject(false) do |is_found, array_value|
      is_found || !!(search_value =~ /#{regex_format % array_value}/)
    end
  end
end

module Mixlib
  class Install
    class Backend
      class Bintray < Base
        class UnknownArchitecture < StandardError; end

        ENDPOINT = "https://bintray.com/api/v1/".freeze

        # Bintray credentials for api read access. These are here intentionally.
        BINTRAY_USERNAME = "mixlib-install@chef".freeze

        BINTRAY_PASSWORD = "a83d3a2ffad50eb9a2230f281a2e19b70fe0db2d".freeze

        DOWNLOAD_URL_ENDPOINT = "https://packages.chef.io".freeze

        def endpoint
          @endpoint ||= ENV.fetch("BINTRAY_ENDPOINT", ENDPOINT)
        end

        # Create filtered list of artifacts
        #
        # @return [Array<ArtifactInfo>] list of artifacts for the configured
        # channel, product name, and product version.
        # @return [ArtifactInfo] arifact info for the configured
        # channel, product name, product version and platform info
        #
        def info
          artifacts = bintray_artifacts

          if options.platform
            artifacts.select! do |a|
              a.platform == options.platform &&
                a.platform_version == options.platform_version &&
                a.architecture == options.architecture
            end
          end

          artifacts.length == 1 ? artifacts.first : artifacts
        end

        private

        #
        # Get latest version for product/channel
        #
        # @return [String] latest version value
        #
        def latest_version
          result = bintray_get("versions/_latest")
          result["name"]
        end

        #
        # Get artifacts for a given version, channel and product_name
        #
        # @return [Array<ArtifactInfo>] Array of info about found artifacts
        #
        def bintray_artifacts
          version = options.product_version == :latest ? latest_version : options.product_version
          results = bintray_get("versions/#{version}/files")

          # Delete .asc files
          results.each { |r| results.delete(r) if r["name"].end_with?(".asc") }

          # Convert results to build records
          results.map { |a| create_artifact(a) }
        end

        #
        # Creates an instance of ArtifactInfo
        #
        # @param artifact_map
        # {
        #   "name" => "chef-12.8.1-1.powerpc.bff",
        #   "path" => "aix/6.1/chef-12.8.1-1.powerpc.bff",
        #   "version" => "12.8.1",
        #   "sha1" => "1206f7be7be8bbece1e9943dcdc0d22fe538718b",
        #   "sha256" => "e49321095a04f51385a59b3f3d7223cd1bddefc2e2f4280edfb0934d00a4fa3f"
        # }
        #
        # @return [ArtifactInfo] ArtifactInfo instance
        #
        def create_artifact(artifact_map)
          platform_info = parse_platform_info(artifact_map)

          url = "#{DOWNLOAD_URL_ENDPOINT}/#{options.channel}/#{artifact_map["path"]}"

          ArtifactInfo.new(
            sha1:             artifact_map["sha1"],
            sha256:           artifact_map["sha256"],
            version:          artifact_map["version"],
            platform:         platform_info[:platform],
            platform_version: platform_info[:platform_version],
            architecture:     platform_info[:architecture],
            url:              url
          )
        end

        #
        # Parses platform info
        #
        # @param artifact_map
        # {
        #   "name" => "chef-12.8.1-1.powerpc.bff",
        #   "path" => "aix/6.1/chef-12.8.1-1.powerpc.bff",
        #   "version" => "12.8.1",
        #   "sha1" => "1206f7be7be8bbece1e9943dcdc0d22fe538718b",
        #   "sha256" => "e49321095a04f51385a59b3f3d7223cd1bddefc2e2f4280edfb0934d00a4fa3f"
        # }
        #
        # @return [Hash] platform, platform_version, architecture
        #
        def parse_platform_info(artifact_map)
          # platform/platform_version/filename
          path = artifact_map["path"].split("/")
          platform = path[0]
          platform_version = path[1]

          filename = artifact_map["name"]
          architecture = if %w{ x86_64 amd64 x64 }.fuzzy_include?(filename)
                           "x86_64"
                         elsif %w{ i386 x86 }.fuzzy_include?(filename)
                           "i386"
                         elsif %w{ powerpc }.fuzzy_include?(filename)
                           "powerpc"
                         elsif %w{ sparc }.fuzzy_include?(filename)
                           "sparc"
                         elsif platform == "mac_os_x"
                           "x86_64"
                         else
                           raise UnknownArchitecture,
                                 "architecture can not be determined for '#{filename}'"
                         end

          {
            platform: platform,
            platform_version: platform_version,
            architecture: architecture,
          }
        end

        def bintray_get(resource)
          uri = URI.parse(endpoint)
          http = Net::HTTP.new(uri.host, uri.port)
          http.use_ssl = (uri.scheme == "https")

          path = "#{uri.path}/packages/chef/#{options.channel}/#{options.product_name}/#{resource}"
          request = Net::HTTP::Get.new(path)
          request.basic_auth(BINTRAY_USERNAME, BINTRAY_PASSWORD)

          res = http.request(request)

          # Raise if response is not 2XX
          res.value
          JSON.parse(res.body)
        end
      end
    end
  end
end
