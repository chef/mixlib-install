#
# Author:: Patrick Wright (<patrick@chef.io>)
# Copyright:: Copyright (c) 2016 Chef, Inc.
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
    class Backend
      class Base
        attr_reader :options

        def initialize(options)
          @options = options
        end

        #
        # Returns the list of artifacts from the configured backend based on the
        # configured product_name, product_version and channel.
        #
        # @abstract Subclasses should define this method.
        #
        # @return Array<ArtifactInfo>
        #   List of ArtifactInfo objects for the available artifacts.
        def available_artifacts
          raise "Must implement available_artifacts method that returns Array<ArtifactInfo>"
        end

        #
        # Returns the list of available versions for a given product_name
        # and channel.
        #
        # @abstract Subclasses should define this method.
        #           Currently this method is only available in the Artifactory
        #           subclass.
        #
        # @return Array<String>
        #   List of available versions as strings.
        def available_versions
          raise "available_versions API is only available for Artifactory backend."
        end

        #
        # See #filter_artifacts
        def info
          filter_artifacts(available_artifacts)
        end

        #
        # Returns true if platform filters are available, false otherwise.
        #
        # Note that we assume #set_platform_info method is used on the Options
        # class to set the platform options.
        #
        # @return TrueClass, FalseClass
        def platform_filters_available?
          !options.platform.nil?
        end

        #
        # Filters and returns the available artifacts based on the configured
        # platform filtering options.
        #
        # @return ArtifactInfo, Array<ArtifactInfo>, []
        #   If the result is a single artifact, this returns ArtifactInfo.
        #   If the result is a list of artifacts, this returns Array<ArtifactInfo>.
        #   If no suitable artifact is found, this returns [].
        def filter_artifacts(artifacts)
          return artifacts unless platform_filters_available?

          # First filter the artifacts based on the platform and architecture
          artifacts.select! do |a|
            a.platform == options.platform && a.architecture == options.architecture
          end

          # Now we are going to filter based on platform_version.
          # We will return the artifact with an exact match if available.
          # Otherwise we will search for a compatible artifact and return it
          # if the compat options is set.
          closest_compatible_artifact = nil

          artifacts.each do |a|
            return a if a.platform_version == options.platform_version

            # We skip the artifacts produced for windows since their platform
            # version is always set to 2008r2 which breaks our `to_f` comparison.
            next if a.platform == "windows"

            # Calculate the closest compatible version.
            # For an artifact to be compatible it needs to be smaller than the
            # platform_version specified in options.
            # To find the closest compatible one we keep a max of the compatible
            # artifacts.
            if closest_compatible_artifact.nil? ||
                (a.platform_version.to_f > closest_compatible_artifact.platform_version.to_f &&
                  a.platform_version.to_f < options.platform_version.to_f )
              closest_compatible_artifact = a
            end
          end

          # If the compat flag is set and if we have found a compatible artifact
          # we are going to use it.
          if options.platform_version_compatibility_mode && closest_compatible_artifact
            return closest_compatible_artifact
          end

           # Otherwise, we return an empty array indicating we do not have any matching artifacts
          return []
        end

        # On windows, if we do not have a native 64-bit package available
        # in the discovered artifacts, we will make 32-bit artifacts available
        # for 64-bit architecture.
        def windows_artifact_fixup!(artifacts)
          new_artifacts = [ ]
          native_artifacts = [ ]

          artifacts.each do |r|
            next if r.platform != "windows"

            # Store all native 64-bit artifacts and clone 32-bit artifacts to
            # be used as 64-bit.
            case r.architecture
            when "i386"
              new_artifacts << r.clone_with(architecture: "x86_64")
            when "x86_64"
              native_artifacts << r.clone
            else
              puts "Unknown architecture '#{r.architecture}' for windows."
            end
          end

          # Now discard the cloned artifacts if we find an equivalent native
          # artifact
          native_artifacts.each do |r|
            new_artifacts.delete_if do |x|
              x.platform_version == r.platform_version
            end
          end

          # add the remaining cloned artifacts to the original set
          artifacts += new_artifacts
        end

        #
        # Normalizes platform and platform_version information that we receive.
        # There are a few entries that we historically published
        # that we need to normalize. They are:
        #   * solaris -> solaris2 & 10 -> 5.10 for solaris.
        #
        # @param [String] platform
        # @param [String] platform_version
        #
        # @return Array<String> [platform, platform_version]
        def normalize_platform(platform, platform_version)
          if platform == "solaris"
            platform = "solaris2"

            # Here platform_version is set to either 10 or 11 and we would like
            # to normalize that to 5.10 and 5.11.
            platform_version = "5.#{platform_version}"
          end

          [platform, platform_version]
        end

        #
        # Normalizes architecture information that we receive from omnibus.architecture
        #
        # @param [String] architecture
        #
        # @return String [architecture]
        def normalize_architecture(architecture)
          case architecture
          when "amd64"
            "x86_64"
          when "i86pc", "i686"
            "i386"
          when "sun4u", "sun4v"
            "sparc"
          else
            architecture
          end
        end
      end
    end
  end
end
