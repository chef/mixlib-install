module Mixlib
  class Install
    class Dist
      # This class is not fully implemented, depending it is not recommended!
      # Binary repository base endpoint
      PRODUCT_ENDPOINT = "https://packages.chef.io".freeze
      # Omnitruck endpoint
      OMNITRUCK_ENDPOINT = "https://omnitruck.chef.io".freeze
      # Default product name
      DEFAULT_PRODUCT = "chef".freeze
      # Default base product page URL
      PRODUCT_URL = "https://downloads.chef.io".freeze
      # Default github org
      GITHUB_ORG = "chef".freeze
    end
  end
end
