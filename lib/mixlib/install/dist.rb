module Mixlib
  class Install
    class Dist
      # This class is not fully implemented, depending it is not recommended!
      # Default project name
      PROJECT_NAME = "Chef".freeze
      # Binary repository base endpoint
      PRODUCT_ENDPOINT = "https://packages.chef.io".freeze
      # Omnitruck endpoint
      OMNITRUCK_ENDPOINT = "https://omnitruck.chef.io".freeze
      # Commercial API endpoint
      COMMERCIAL_API_ENDPOINT = "https://chefdownload-commercial.chef.io".freeze
      # Trial API endpoint
      TRIAL_API_ENDPOINT = "https://chefdownload-trial.chef.io".freeze
      # Default product name
      DEFAULT_PRODUCT = "chef".freeze
      # Default download page URL
      DOWNLOADS_PAGE = "https://downloads.chef.io".freeze
      # Default github org
      GITHUB_ORG = "chef".freeze
      # Bug report URL
      BUG_URL = "https://github.com/chef/omnitruck/issues/new".freeze
      # Support ticket URL
      SUPPORT_URL = "https://www.chef.io/support/tickets".freeze
      # Resources URL
      RESOURCES_URL = "https://www.chef.io/support".freeze
      # MacOS volume name
      MACOS_VOLUME = "chef_software".freeze
      # Omnibus Windows install directory name
      OMNIBUS_WINDOWS_INSTALL_DIR = "opscode".freeze
      # Omnibus Linux install directory name
      OMNIBUS_LINUX_INSTALL_DIR = "/opt".freeze
      # Habitat Windows install directory name
      HABITAT_WINDOWS_INSTALL_DIR = "hab\\pkgs".freeze
      # Habitat Linux install directory name
      HABITAT_LINUX_INSTALL_DIR = "/hab/pkgs".freeze

      # Check if a license_id is for trial API
      # @param license_id [String] the license ID to check
      # @return [Boolean] true if license_id indicates trial API usage
      def self.trial_license?(license_id)
        !license_id.nil? && !license_id.to_s.empty? &&
          license_id.start_with?("free-", "trial-")
      end

      # Check if a license_id is for commercial API
      # @param license_id [String] the license ID to check
      # @return [Boolean] true if license_id indicates commercial API usage
      def self.commercial_license?(license_id)
        !license_id.nil? && !license_id.to_s.empty? &&
          !trial_license?(license_id)
      end
    end
  end
end
