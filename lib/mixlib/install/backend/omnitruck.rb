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

require 'net/http'
require 'json'
require 'mixlib/install/artifact_info'

module Mixlib
  class Install
    class Backend
      class Omnitruck

        attr_accessor :options

        def initialize(options)
          @options = options
        end

        def info
          parameters = {
            p: options.platform,
            pv: options.platform_version,
            m: options.architecture,
            v: options.product_version
          }

          endpoint = 'https://omnitruck.chef.io'

          uri = URI.parse(endpoint)
          http = Net::HTTP.new(uri.host, uri.port)
          http.use_ssl = (uri.scheme == 'https')

          path = "/#{options.channel}/#{options.product_name}/metadata"
          full_path = [path, URI.encode_www_form(parameters)].join('?')
          request = Net::HTTP::Get.new(full_path)
          request['Accept'] = 'application/json'

          res = http.request(request)

          # Raise if response is not 2XX
          res.value
          ArtifactInfo.from_json(res.body)
        end
      end
    end
  end
end
