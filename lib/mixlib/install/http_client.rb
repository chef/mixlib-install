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

      #
      # Execute GET request. Automatically configures SSL and Proxy
      # based on URI scheme and proxy settings
      #
      # @param path [String] URI path
      #
      # @return [HTTP::Response] response
      #
      def get(path)
        url = File.join(endpoint, path)

        if proxy_address
          proxy_params = [proxy_address, proxy_port]
          proxy_params << [proxy_username, proxy_password] if proxy_username
          client.via(*proxy_params).get(url)
        else
          client.get(url)
        end
      end

      #
      # Execute GET request. Automatically configures SSL and Proxy
      # based on URI scheme and proxy settings
      #
      # @param path [String] URI path
      #
      # @return [JSON] response body as json
      #
      def get_json(path)
        JSON.parse(self.get(path).to_s)
      end

      #
      # Create HTTP::Client with default and/or custom user agent headers
      #
      # @return [HTTP::Client] client
      #
      def client
        headers = { "User-Agent" => Util.user_agent_string(user_agent_headers) }
        HTTP[headers]
      end
    end
  end
end
