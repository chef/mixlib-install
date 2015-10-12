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
          params = {
            "repos" => "omnibus-current-local",
            "omnibus.platform" => options.platform,
            "omnibus.platform_version" => options.platform_version,
            "omnibus.architecture" => options.architecture,
            "omnibus.version" => options.product_version
          }

          headers = { "X-Result-Detail" => "properties" }

          begin
            artifact = client.get("/api/search/prop", params, headers)
          rescue Errno::ETIMEDOUT => e
            raise e, "unstable channel uses endpoint #{ARTIFACTORY_ENDPOINT} \
which is currently only accessible through Chef's internal network."
          end

          ArtifactInfo.new(extract_data(artifact))
        end

        private

        def extract_data(artifact)
          results = artifact["results"].first
          {
            md5:              results["properties"]["omnibus.md5"].first,
            sha256:           results["properties"]["omnibus.sha256"].first,
            version:          results["properties"]["omnibus.version"].first,
            platform:         results["properties"]["omnibus.platform"].first,
            platform_version: results["properties"]["omnibus.platform_version"].first,
            architecture:     results["properties"]["omnibus.architecture"].first,
            url:              results["uri"]
          }
        end
      end
    end
  end
end
