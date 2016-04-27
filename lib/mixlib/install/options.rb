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

require "mixlib/install/product"
require "mixlib/versioning"

module Mixlib
  class Install
    class Options
      class InvalidOptions < ArgumentError; end

      attr_reader :options

      OMNITRUCK_CHANNELS = [:stable, :current]
      ARTIFACTORY_CHANNELS = [:unstable]
      ALL_SUPPORTED_CHANNELS = OMNITRUCK_CHANNELS + ARTIFACTORY_CHANNELS
      SUPPORTED_PRODUCT_NAMES = PRODUCT_MATRIX.products
      SUPPORTED_SHELL_TYPES = [:ps1, :sh]
      SUPPORTED_OPTIONS = [
        :architecture,
        :channel,
        :platform,
        :platform_version,
        :product_name,
        :product_version,
        :shell_type,
        :platform_version_compatibility_mode,
      ]

      def initialize(options)
        @options = options

        validate!
      end

      def validate!
        validate_options!
      end

      def validate_options!
        errors = []

        errors << validate_product_names
        errors << validate_channels
        errors << validate_shell_type

        unless errors.compact.empty?
          raise InvalidOptions, errors.join("\n")
        end
      end

      SUPPORTED_OPTIONS.each do |option|
        define_method option do
          options[option] || options[option.to_s] || default_options[option]
        end
      end

      def for_artifactory?
        ARTIFACTORY_CHANNELS.include?(channel)
      end

      def for_bintray?
        [:stable, :current].include?(channel)
      end

      def for_omnitruck?
        OMNITRUCK_CHANNELS.include?(channel)
      end

      def for_ps1?
        platform == "windows" || shell_type == :ps1
      end

      def latest_version?
        product_version.to_sym == :latest
      end

      #
      # Set the platform info on the instance
      # info [Hash]
      #  Hash with keys :platform, :platform_version and :architecture
      #
      def set_platform_info(info)
        options[:platform] = info[:platform]
        options[:platform_version] = info[:platform_version]
        options[:architecture] = info[:architecture]

        validate_options!
      end

      private

      def default_options
        {
          shell_type: :sh,
          platform_version_compatibility_mode: false,
        }
      end

      def validate_product_names
        unless SUPPORTED_PRODUCT_NAMES.include? product_name
          <<-EOS
Unknown product name #{product_name}.
Must be one of: #{SUPPORTED_PRODUCT_NAMES.join(", ")}
          EOS
        end
      end

      def validate_channels
        unless ALL_SUPPORTED_CHANNELS.include? channel
          <<-EOS
Unknown channel #{channel}.
Must be one of: #{ALL_SUPPORTED_CHANNELS.join(", ")}
          EOS
        end
      end

      def validate_shell_type
        unless SUPPORTED_SHELL_TYPES.include? shell_type
          <<-EOS
Unknown shell type.
Must be one of: #{SUPPORTED_SHELL_TYPES.join(", ")}
          EOS
        end
      end

    end
  end
end
