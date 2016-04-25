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

require "json"
require "mixlib/install/backend/base"
require "mixlib/install/artifact_info"

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
        class VersionNotFound < StandardError; end
        # Bintray credentials for api read access. These are here intentionally.
        BINTRAY_USERNAME = "mixlib-install@chef".freeze
        BINTRAY_PASSWORD = "a83d3a2ffad50eb9a2230f281a2e19b70fe0db2d".freeze

        ENDPOINT = "https://bintray.com/api/v1/".freeze
        DOWNLOAD_URL_ENDPOINT = "https://packages.chef.io".freeze
        COMPAT_DOWNLOAD_URL_ENDPOINT = "http://chef.bintray.com".freeze

        def endpoint
          @endpoint ||= ENV.fetch("BINTRAY_ENDPOINT", ENDPOINT)
        end

        #
        # Makes a GET request to bintray for the given path.
        #
        # @param [String] path
        #   "/api/v1/packages/chef" is prepended to the given path.
        #
        # @return [String] JSON parsed string of the bintray response
        #
        def bintray_get(path)
          uri = URI.parse(endpoint)
          http = Net::HTTP.new(uri.host, uri.port)
          http.use_ssl = (uri.scheme == "https")

          full_path = File.join(uri.path, "packages/chef", path)
          request = Net::HTTP::Get.new(full_path)
          request.basic_auth(BINTRAY_USERNAME, BINTRAY_PASSWORD)

          res = http.request(request)

          # Raise if response is not 2XX
          res.value
          JSON.parse(res.body)
        end

        #
        # Get latest version for product/channel
        #
        # @return [String] latest version value
        #
        def latest_version
          result = bintray_get("#{options.channel}/#{options.product_name}/versions/_latest")
          result["name"]
        end

        #
        # Get artifacts for a given version, channel and product_name
        #
        # @return [Array<ArtifactInfo>] Array of info about found artifacts
        #
        def available_artifacts
          version = options.latest_version? ? latest_version : options.product_version
          begin
            results = bintray_get("#{options.channel}/#{options.product_name}/versions/#{version}/files")
          rescue Net::HTTPServerException => e
            if e.message =~ /404 "Not Found"/
              raise VersionNotFound,
                "Specified version (#{version}) not found for #{options.product_name} in #{options.channel} channel."
            else
              raise
            end
          end

          #
          # Delete files that we don't want as part of the artifact info array
          # Windows: .asc files
          # MAC OS _X: .pkg files which are uploaded along with dmg files for
          # some chef versions.
          #
          %w{ asc pkg }.each do |ext|
            results.reject! { |r| r["name"].end_with?(".#{ext}") }
          end

          # Convert results to build records
          results.map! { |a| create_artifact(a) }

          windows_artifact_fixup!(results)
        end

        # On windows, if we do not have a native 64-bit package available
        # in the discovered artifacts, we will make 32-bit artifacts available
        # for 64-bit architecture.
        def windows_artifact_fixup!(artifacts)
          new_artifacts = [ ]
          native_artifacts = [ ]

          artifacts.each do |r|
            next if r.platform != "windows"

            # Store all native 64-bit artifacts and clone 32-bit artifacts to
            # be used as 64-bit.
            case r.architecture
            when "i386"
              new_artifacts << r.clone_with(architecture: "x86_64")
            when "x86_64"
              native_artifacts << r.clone
            else
              puts "Unknown architecture '#{r.architecture}' for windows."
            end
          end

          # Now discard the cloned artifacts if we find an equivalent native
          # artifact
          native_artifacts.each do |r|
            new_artifacts.delete_if do |x|
              x.platform_version == r.platform_version
            end
          end

          # add the remaining cloned artifacts to the original set
          artifacts += new_artifacts
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

          ArtifactInfo.new(
            sha1:             artifact_map["sha1"],
            sha256:           artifact_map["sha256"],
            version:          artifact_map["version"],
            platform:         platform_info[:platform],
            platform_version: platform_info[:platform_version],
            architecture:     platform_info[:architecture],
            url:              url(artifact_map)
          )
        end

        #
        # Creates the URL for the artifact.
        #
        # For some older platform & platform_version combinations we need to
        # use COMPAT_DOWNLOAD_URL_ENDPOINT since these versions have an
        # OpenSSL version that can not verify the DOWNLOAD_URL_ENDPOINT
        # based urls
        #
        # @param artifact_map
        #   see #create_artifact for details.
        #
        # @return [String] url for the artifact
        #
        def url(artifact_map)
          platform_info = parse_platform_info(artifact_map)

          base_url = case "#{platform_info[:platform]}-#{platform_info[:platform_version]}"
                     when "freebsd-9", "el-5", "solaris2-5.9", "solaris2-5.10"
                       COMPAT_DOWNLOAD_URL_ENDPOINT
                     else
                       DOWNLOAD_URL_ENDPOINT
                     end

          "#{base_url}/#{options.channel}/#{artifact_map["path"]}"
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
          platform, platform_version = normalize_platform(platform, platform_version)

          filename = artifact_map["name"]
          architecture = parse_architecture_from_file_name(filename)

          {
            platform: platform,
            platform_version: platform_version,
            architecture: architecture,
          }
        end

        #
        # Normalizes platform and platform_version information that we receive
        # from bintray. There are a few entries that we historically published
        # that we need to normalize. They are:
        #   * solaris -> solaris2 & 10 -> 5.10 for solaris.
        #
        # @param [String] platform
        # @param [String] platform_version
        #
        # @return Array<String> [platform, platform_version]
        def normalize_platform(platform, platform_version)
          if platform == "solaris"
            platform = "solaris2"

            # Here platform_version is set to either 10 or 11 and we would like
            # to normalize that to 5.10 and 5.11.

            platform_version = "5.#{platform_version}"
          end

          [platform, platform_version]
        end

        #
        # Determines the architecture for which a file is published from from
        # filename.
        #
        # We determine the architecture  based on the filename of the artifact
        # since architecture the artifact is published for is not available
        # in bintray.
        #
        # IMPORTANT: This function is heavily used by omnitruck poller. Make
        #   sure you test with `./poller` if you change this function.
        #
        # @param [String] filename
        #
        # @return [String]
        #   one of the standardized architectures for Chef packages:
        #   x86_64, i386, powerpc, sparc, ppc64, ppc64le
        def parse_architecture_from_file_name(filename)
          #
          # We first map the different variations of architectures that we have
          # used historically to our final set.
          #
          if %w{ x86_64 amd64 x64 }.fuzzy_include?(filename)
            "x86_64"
          elsif %w{ i386 x86 i86pc i686 }.fuzzy_include?(filename)
            "i386"
          elsif %w{ powerpc }.fuzzy_include?(filename)
            "powerpc"
          elsif %w{ sparc sun4u sun4v }.fuzzy_include?(filename)
            "sparc"
          # Note that ppc64le should come before ppc64 otherwise our search
          # will think ppc64le matches ppc64. Ubuntu also calls it ppc64el.
          elsif %w{ ppc64le ppc64el }.fuzzy_include?(filename)
            "ppc64le"
          elsif %w{ ppc64 }.fuzzy_include?(filename)
            "ppc64"
          #
          # From here on we need to deal with historical versions
          # that we have published without any architecture in their
          # names.
          #
          #
          # All dmg files are published for x86_64
          elsif filename.end_with?(".dmg")
            "x86_64"
          #
          # The msi files we catch here are versions that are older than the
          # ones which we introduced 64 builds. Therefore they should map to
          # i386
          elsif filename.end_with?(".msi")
            "i386"
          #
          # sh files are the packaging format we were using before dmg on Mac.
          # They map to x86_64
          elsif filename.end_with?(".sh")
            "x86_64"
          #
          # We have two common file names for solaris packages. E.g:
          #   chef-11.12.8-2.solaris2.5.10.solaris
          #   chef-11.12.8-2.solaris2.5.9.solaris
          # These were build on two boxes:
          #   Solaris 9 => sparc
          #   Solaris 10 => i386
          elsif filename.end_with?(".solaris2.5.10.solaris")
            "i386"
          elsif filename.end_with?(".solaris2.5.9.solaris")
            "sparc"
          else
            raise UnknownArchitecture,
              "architecture can not be determined for '#{filename}'"
          end
        end
      end
    end
  end
end
