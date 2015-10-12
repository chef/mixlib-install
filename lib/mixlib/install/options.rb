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

      OMNITRUCK_CHANNELS = [:stable, :current]
      ARTIFACTORY_CHANNELS = [:unstable]
      ALL_SUPPORTED_CHANNELS = OMNITRUCK_CHANNELS + ARTIFACTORY_CHANNELS
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

        unless ALL_SUPPORTED_CHANNELS.include? channel
          errors << "Unknown channel #{channel}. \
Must be one of: #{ALL_SUPPORTED_CHANNELS.join(", ")}"
        end

        if ARTIFACTORY_CHANNELS.include?(channel) &&
            product_version !~ /^\d+.\d+.\d+\+[0-9]{14}$/
          errors << "Version must match pattern '1.2.3+12345678901234' when \
using channels #{ARTIFACTORY_CHANNELS.join(", ")}"
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
