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

module Mixlib
  class Install
    class Options
      class InvalidOptions < ArgumentError; end

      attr_accessor :options

      SUPPORTED_CHANNELS = [:stable, :current]
      SUPPORTED_PRODUCT_NAMES = %w[chef chefdk]
      SUPPORTED_OPTIONS = [:channel, :product_name, :product_version,
                           :platform, :platform_version, :architecture]

      def initialize(options)
        @options = options
        validate_options!
      end

      def validate_options!
        errors = []
        unless SUPPORTED_PRODUCT_NAMES.include? product_name
          errors << "Unknown product name #{product_name}. \
Must be one of: #{SUPPORTED_PRODUCT_NAMES.join(", ")}"
        end

        unless SUPPORTED_CHANNELS.include? channel
          errors << "Unknown channel #{channel}. Must be one of: #{SUPPORTED_CHANNELS.join(", ")}"
        end

        unless errors.empty?
          raise InvalidOptions, errors.join("\n")
        end
      end

      SUPPORTED_OPTIONS.each do |option|
        define_method option do
          options[option] || options[option.to_s]
        end
      end
    end
  end
end
