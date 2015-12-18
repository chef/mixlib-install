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

require "net/http"
require "json"
require "mixlib/install/artifact_info"
require "artifactory"

module Mixlib
  class Install
    class Backend
      class Artifactory
        class ConnectionError < StandardError; end
        class AuthenticationError < StandardError; end

        ENDPOINT = "http://artifactory.chef.co".freeze

        attr_accessor :options

        def initialize(options)
          @options = options
        end

        # Create filtered list of artifacts
        #
        # @return [Array<ArtifactInfo>] list of artifacts for the configured
        # channel, product name, and product version.
        # @return [ArtifactInfo] arifact info for the configured
        # channel, product name, product version and platform info
        #
        def info
          artifacts = artifactory_info.collect { |a| create_artifact(a) }

          artifacts_for_version = artifacts.find_all do |a|
            a.version == options.resolved_version(artifacts)
          end

          if options.platform
            artifacts_for_version.find do |a|
              a.platform == options.platform &&
                a.platform_version == options.platform_version &&
                a.architecture == options.architecture
            end
          else
            artifacts_for_version
          end
        end

        # Fetches all artifacts from the configured Artifactory repository using
        # channel and product name as search criteria
        #
        # @return [Array<Hash>] list of artifactory hash data
        #
        # Hash data:
        #   download_uri: The full url download path
        #   <property_name>: The names of the properties associcated to the artifact
        #
        def artifactory_info
          query = <<-QUERY
items.find(
  {"repo": "omnibus-#{options.channel}-local"},
  {"@omnibus.project": "#{options.product_name}"}
).include("repo", "path", "name", "property")
          QUERY

          results = artifactory_request do
            client.post("/api/search/aql", query, "Content-Type" => "text/plain")
          end

          # Merge artifactory properties and downloadUri to a flat Hash
          results["results"].collect do |result|
            { "downloadUri" => generate_download_uri(result) }.merge(
              map_properties(result["properties"])
            )
          end
        end

        def create_artifact(artifact_map)
          ArtifactInfo.new(
            md5:              artifact_map["omnibus.md5"],
            sha256:           artifact_map["omnibus.sha256"],
            version:          artifact_map["omnibus.version"],
            platform:         artifact_map["omnibus.platform"],
            platform_version: artifact_map["omnibus.platform_version"],
            architecture:     artifact_map["omnibus.architecture"],
            url:              artifact_map["downloadUri"]
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

        # Construct the downloadUri from raw artifactory data
        #
        def generate_download_uri(result)
          uri = []
          uri << endpoint.sub(/\/$/, "")
          uri << result["repo"]
          uri << result["path"]
          uri << result["name"]
          uri.join("/")
        end

        def client
          @client ||= ::Artifactory::Client.new(
            endpoint: endpoint,
            username: ENV["ARTIFACTORY_USERNAME"],
            password: ENV["ARTIFACTORY_PASSWORD"]
          )
        end

        def endpoint
          @endpoint ||= ENV.fetch("ARTIFACTORY_ENDPOINT", ENDPOINT)
        end

        def artifactory_request
          begin
            results = yield
          rescue Errno::ETIMEDOUT, ::Artifactory::Error::ConnectionError
            raise ConnectionError, <<-EOS
Artifactory endpoint '#{::Artifactory.endpoint}' is unreachable. Check that
the endpoint is correct and there is an open connection to Chef's private network.
            EOS
          rescue ::Artifactory::Error::HTTPError => e
            if e.code == 401 && e.message =~ /Bad credentials/
              raise AuthenticationError, <<-EOS
Artifactory server denied credentials. Verify ARTIFACTORY_USERNAME and
ARTIFACTORY_PASSWORD environment variables are configured properly.
              EOS
            else
              raise e
            end
          end

          results
        end
      end
    end
  end
end
