#
# Author:: Patrick Wright (<patrick@chef.io>)
# Copyright:: Copyright (c) 2015-2016 Chef, Inc.
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
require "mixlib/install/artifact_info"
require "mixlib/install/backend/base"
require "mixlib/install/product"
require "net/http"

module Mixlib
  class Install
    class Backend
      class PackageRouter < Base
        class NoArtifactsError < StandardError; end

        ENDPOINT = "https://packages.chef.io".freeze

        # Create filtered list of artifacts
        #
        # @return [Array<ArtifactInfo>] list of artifacts for the configured
        # channel, product name, and product version.
        def available_artifacts
          artifacts = if options.latest_version?
                        latest_version
                      else
                        artifacts_for_version(options.product_version)
                      end

          windows_artifact_fixup!(artifacts)
        end

        #
        # Gets available versions from Artifactory via AQL.
        #
        # @return [Array<String>] Array of available versions
        def available_versions
          items = get("/api/v1/#{options.channel}/#{omnibus_project}/versions")["results"]

          # Filter out the partial builds if we are in :unstable channel
          # In other channels we do not need to do this since all builds are
          # always complete. Infact we should not do this since for some arcane
          # builds like Chef Client 10.X we do not have build record created in
          # artifactory.
          if options.channel == :unstable
            # We check if "artifacts" field contains something since it is only
            # populated with the build record if "artifact.module.build" exists.
            items.reject! { |i| i["artifacts"].nil? }
          end

          # We are only including a single property, version and that exists
          # under the properties in the following structure:
          # "properties" => [ {"key"=>"omnibus.version", "value"=>"12.13.3"} ]
          items.map! { |i| i["properties"].first["value"] }
          items.uniq
        end

        #
        # Get artifacts for the latest version, channel and product_name
        #
        # @return [Array<ArtifactInfo>] Array of info about found artifacts
        def latest_version
          # Get the list of builds from the REST api.
          # We do this because a user in the readers group does not have
          # permissions to run aql against builds.
          builds = get("/api/v1/build/#{omnibus_project}")

          if builds.nil?
            raise NoArtifactsError, <<-MSG
Can not find any builds for #{options.product_name} in #{::PackageRouter.endpoint}.
            MSG
          end

          # Output we get is something like:
          # {
          #   "buildsNumbers": [
          #     {"uri"=>"/12.5.1+20151213083009", "started"=>"2015-12-13T08:40:19.238+0000"},
          #     {"uri"=>"/12.6.0+20160111212038", "started"=>"2016-01-12T00:25:35.762+0000"},
          #     ...
          #   ]
          # }
          # First we sort based on started
          builds["buildsNumbers"].sort_by! { |b| b["started"] }.reverse!

          # Now check if the build is in the requested channel or not
          # Note that if you do this for any channel other than :unstable
          # it will run a high number of queries but it is fine because we
          # are using artifactory only for :unstable channel
          builds["buildsNumbers"].each do |build|
            version = build["uri"].delete("/")
            artifacts = artifacts_for_version(version)

            return artifacts unless artifacts.empty?
          end

          # we could not find any matching artifacts
          []
        end

        #
        # Get artifacts for a given version, channel and product_name
        #
        # @return [Array<ArtifactInfo>] Array of info about found artifacts
        def artifacts_for_version(version)
          begin
            results = get("/api/v1/#{options.channel}/#{omnibus_project}/#{version}/artifacts")["results"]
          rescue Net::HTTPServerException => e
            if e.message =~ /404/
              return []
            else
              raise e
            end
          end

          # Merge artifactory properties to a flat Hash
          results.collect! do |result|
            {
              "filename" => result["name"],
            }.merge(
              map_properties(result["properties"])
            )
          end

          # Convert results to build records
          results.map { |a| create_artifact(a) }
        end

        #
        # GET request
        #
        def get(url)
          uri = URI.parse(endpoint)
          http = Net::HTTP.new(uri.host, uri.port)
          http.use_ssl = (uri.scheme == "https")

          full_path = File.join(uri.path, url)
          request = Net::HTTP::Get.new(full_path)

          res = http.request(request)

          res.value
          JSON.parse(res.body)
        end

        def create_artifact(artifact_map)
          platform, platform_version = normalize_platform(artifact_map["omnibus.platform"],
            artifact_map["omnibus.platform_version"])

          chef_standard_path = generate_chef_standard_path(options.channel,
            artifact_map["omnibus.project"],
            artifact_map["omnibus.version"],
            platform,
            platform_version,
            artifact_map["filename"]
          )

          ArtifactInfo.new(
            md5:              artifact_map["omnibus.md5"],
            sha256:           artifact_map["omnibus.sha256"],
            sha1:             artifact_map["omnibus.sha1"],
            version:          artifact_map["omnibus.version"],
            platform:         platform,
            platform_version: platform_version,
            architecture:     normalize_architecture(artifact_map["omnibus.architecture"]),
            url:              chef_standard_path
          )
        end

        private

        # Converts Array<Hash> where the Hash is a key pair and
        # value pair to a simplifed key/pair Hash
        #
        def map_properties(properties)
          return {} if properties.nil?
          properties.each_with_object({}) do |prop, h|
            h[prop["key"]] = prop["value"]
          end
        end

        # Generates a chef standard download uri in the form of
        # http://endpoint/files/:channel/:project/:version/:platform/:platform_version/:file
        def generate_chef_standard_path(channel, project, version, platform, platform_version, filename)
          uri = []
          uri << endpoint.sub(/\/$/, "")
          uri << "files"
          uri << channel
          uri << project
          uri << version
          uri << platform
          uri << platform_version
          uri << filename
          uri.join("/")
        end

        def endpoint
          @endpoint ||= ENV.fetch("PACKAGE_ROUTER_ENDPOINT", ENDPOINT)
        end

        def omnibus_project
          @omnibus_project ||= PRODUCT_MATRIX.lookup(options.product_name, options.product_version).omnibus_project
        end

        #
        # Normalizes architecture information that we receive.
        #
        # @param [String] architecture
        #
        # @return String [architecture]
        def normalize_architecture(architecture)
          if %w{ sun4u sun4v }.include?(architecture)
            architecture = "sparc"
          end

          architecture
        end
      end
    end
  end
end
