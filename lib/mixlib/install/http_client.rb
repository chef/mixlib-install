require "http"
require "mixlib/install/util"

module Mixlib
  class Install
    class HTTPClient
      attr_reader :proxy_address, :proxy_port, :proxy_username, :proxy_password, :endpoint, :user_agent_headers

      def initialize(endpoint, options)
        @endpoint = endpoint
        @user_agent_headers = options.user_agent_headers
        @proxy_address = options.proxy_address
        @proxy_port = options.proxy_port
        @proxy_username = options.proxy_username
        @proxy_password = options.proxy_password
      end

      def get(path)
        url = File.join(endpoint, path)

        if proxy_address
          proxy_params = [proxy_address, proxy_port]
          proxy_params.push(proxy_username, proxy_password) if proxy_username
          http.via(*proxy_params).get(url)
        else
          http.get(url)
        end
      end

      def get_json(path)
        JSON.parse(self.get(path).to_s)
      end

      private

      def http
        headers = {
          "User-Agent" => Util.user_agent_string(user_agent_headers),
        }

        HTTP[headers]
      end
    end
  end
end
