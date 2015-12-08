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

      attr_reader :options
      attr_reader :errors
      attr_reader :defaults

      OMNITRUCK_CHANNELS = [:stable, :current]
      ARTIFACTORY_CHANNELS = [:unstable]
      ALL_SUPPORTED_CHANNELS = OMNITRUCK_CHANNELS + ARTIFACTORY_CHANNELS
      SUPPORTED_PRODUCT_NAMES = %w[chef chefdk]
      SUPPORTED_SHELL_TYPES = [:ps1, :sh]
      SUPPORTED_OPTIONS = [
        :architecture,
        :channel,
        :platform,
        :platform_version,
        :product_name,
        :product_version,
        :shell_type
      ]

      def initialize(options)
        @options = options
        @errors = []
        @defaults = {
          shell_type: :sh
        }
        validate_options!
      end

      def validate_options!
        validate_product_names
        validate_channels
        validate_unstable_version
        validate_platform_info
        validate_shell_type

        unless errors.empty?
          raise InvalidOptions, errors.join("\n")
        end
      end

      SUPPORTED_OPTIONS.each do |option|
        define_method option do
          options[option] || options[option.to_s] || defaults[option]
        end
      end

      def for_artifactory?
        ARTIFACTORY_CHANNELS.include?(channel)
      end

      def for_omnitruck?
        OMNITRUCK_CHANNELS.include?(channel)
      end

      def for_ps1?
        platform == "windows" || shell_type == :ps1
      end

      private

      def validate_product_names
        unless SUPPORTED_PRODUCT_NAMES.include? product_name
          errors << "Unknown product name #{product_name}. \
Must be one of: #{SUPPORTED_PRODUCT_NAMES.join(", ")}"
        end
      end

      def validate_channels
        unless ALL_SUPPORTED_CHANNELS.include? channel
          errors << "Unknown channel #{channel}. \
Must be one of: #{ALL_SUPPORTED_CHANNELS.join(", ")}"
        end
      end

      def validate_unstable_version
        if for_artifactory? && product_version !~ /^\d+.\d+.\d+\+[0-9]{14}$/
          errors << "Version must match pattern '1.2.3+12345678901234' when \
using channels #{ARTIFACTORY_CHANNELS.join(", ")}"
        end
      end

      def validate_platform_info
        platform_opts = [platform, platform_version, architecture]
        if (platform_opts.any?(&:nil?)) &&
            (platform_opts.any? { |opt| !opt.nil? })
          errors << "platform, platform version, and architecture are all \
required when specifying Platform options."
        end
      end

      def validate_shell_type
        unless SUPPORTED_SHELL_TYPES.include? shell_type
          errors << "Unknown shell type. \
Must be one of: #{SUPPORTED_SHELL_TYPES.join(", ")}"
        end
      end
    end
  end
end
