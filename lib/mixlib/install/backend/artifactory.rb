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
        ARTIFACTORY_ENDPOINT = "http://artifactory.chef.co".freeze

        attr_reader :options
        attr_reader :client

        def initialize(options)
          @options = options
          @client = ::Artifactory::Client.new(endpoint: ARTIFACTORY_ENDPOINT)
        end

        def info
          begin
            results = client.get("/api/search/prop", params, headers)["results"]
          rescue Errno::ETIMEDOUT => e
            raise e, "unstable channel uses endpoint #{ARTIFACTORY_ENDPOINT} \
which is currently only accessible through Chef's internal network."
          end

          if options.platform
            artifact(results.first)
          else
            results.collect do |result|
              artifact(result)
            end
          end
        end

        private

        def artifact(result)
          ArtifactInfo.new(
            md5:              result["properties"]["omnibus.md5"].first,
            sha256:           result["properties"]["omnibus.sha256"].first,
            version:          result["properties"]["omnibus.version"].first,
            platform:         result["properties"]["omnibus.platform"].first,
            platform_version: result["properties"]["omnibus.platform_version"].first,
            architecture:     result["properties"]["omnibus.architecture"].first,
            url:              result["downloadUri"]
          )
        end

        def params
          params = {
            "repos" => "omnibus-unstable-local",
            "omnibus.version" => options.product_version
          }

          if options.platform
            params["omnibus.platform"] = options.platform
            params["omnibus.platform_version"] = options.platform_version
            params["omnibus.architecture"] = options.architecture
          end

          params
        end

        def headers
          { "X-Result-Detail" => "info, properties" }
        end
      end
    end
  end
end
