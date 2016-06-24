#
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

require "mixlib/versioning"

module Mixlib
  class Install
    class Product
      def initialize(&block)
        instance_eval(&block)
      end

      DSL_PROPERTIES = [
        :config_file,
        :ctl_command,
        :package_name,
        :product_name,
      ]

      #
      # DSL methods can receive either a String or a Proc to calculate the
      # value of the property later on based on the version.
      # We error out if we get both the String and Proc, and we return the value
      # of the property if we do not receive anything.
      #
      # @param [String] prop_string
      #   value to be set in String form
      # @param [Proc] block
      #   value to be set in Proc form
      #
      # @return [String] value of the property
      #
      DSL_PROPERTIES.each do |prop|
        define_method prop do |prop_string = nil, &block|
          if block.nil?
            if prop_string.nil?
              value = instance_variable_get("@#{prop}".to_sym)
              return nil if value.nil?

              if value.is_a? String
                value
              else
                value.call(version_for(version))
              end
            else
              instance_variable_set("@#{prop}".to_sym, prop_string)
            end
          else
            raise "Can not use String and Proc at the same time for #{prop}." if !prop_string.nil?
            instance_variable_set("@#{prop}".to_sym, block)
          end
        end
      end

      #
      # Sets or retrieves the version for the product. This is used later
      # when we are reading the value of a property if a Proc is specified
      #
      def version(value = nil)
        if value.nil?
          @version
        else
          @version = value
        end
      end

      #
      # Helper method to convert versions from String to Mixlib::Version
      #
      # @param [String] version_string
      #   value to be set in String form
      #
      # @return [Mixlib::Version]
      def version_for(version_string)
        Mixlib::Versioning.parse(version_string)
      end
    end

    class ProductMatrix
      def initialize(&block)
        @product_map = {}
        instance_eval(&block)
      end

      #
      # The only DSL method of this class. It creates a Product with given
      # `key` and stores it.
      #
      def product(key, &block)
        @product_map[key] = Product.new(&block)
      end

      #
      # Fetches the keys of available products.
      #
      # @return Array[String] of keys
      def products
        @product_map.keys
      end

      #
      # Looks up a product and sets version on it to be used later by the
      # Product.
      #
      # @param [String] key
      #   Lookup key of the product.
      # @param [String] version
      #   Version to be set for the product. By default version is set to :latest
      #
      # @return [Product]
      def lookup(key, version = :latest)
        product = @product_map[key]
        # We set the lookup version for the product to a very high number in
        # order to mimic :latest so that one does not need to handle this
        # symbol explicitly when constructing logic based on version numbers.
        version = "1000.1000.1000" if version.to_sym == :latest
        product.version(version)
        product
      end
    end
  end
end

#
# If you are making a change to PRODUCT_MATRIX, please make sure
# you run `bundle exec rake matrix` at the home of this repository
# to update PRODUCT_MATRIX.md.
#
PRODUCT_MATRIX = Mixlib::Install::ProductMatrix.new do
  # Products in alphabetical order

  product "analytics" do
    product_name "Analytics Platform"
    package_name "opscode-analytics"
    ctl_command "opscode-analytics-ctl"
    config_file "/etc/opscode-analytics/opscode-analytics.rb"
  end

  product "angry-omnibus-toolchain" do
    product_name "Angry Omnibus Toolchain"
    package_name "angry-omnibus-toolchain"
  end

  product "angrychef" do
    product_name "Angry Chef Client"
    package_name "angrychef"
  end

  product "chef" do
    product_name "Chef Client"
    package_name "chef"
  end

  product "chef-backend" do
    product_name "Chef Backend"
    package_name "chef-backend"
    ctl_command "chef-backend-ctl"
    config_file "/etc/chef-backend/chef-backend.rb"
  end

  product "chef-server" do
    product_name "Chef Server"
    package_name do |v|
      if (v < version_for("12.0.0")) && (v > version_for("11.0.0"))
        "chef-server"
      else
        "chef-server-core"
      end
    end
    ctl_command "chef-server-ctl"
    config_file "/etc/opscode/chef-server.rb"
  end

  product "chef-server-ha-provisioning" do
    product_name "Chef Server HA Provisioning for AWS"
    package_name "chef-server-ha-provisioning"
  end

  product "chefdk" do
    product_name "Chef Development Kit"
    package_name "chefdk"
  end

  product "compliance" do
    product_name "Chef Compliance"
    package_name "chef-compliance"
    ctl_command "chef-compliance-ctl"
    config_file "/etc/chef-compliance/chef-compliance.rb"
  end

  product "delivery" do
    product_name "Delivery"
    package_name "delivery"
    ctl_command "delivery-ctl"
    config_file "/etc/delivery/delivery.rb"
  end

  product "ha" do
    product_name "Chef Server High Availability addon"
    package_name "chef-ha"
    config_file "/etc/opscode/chef-server.rb"
  end

  product "manage" do
    product_name "Management Console"
    package_name do |v|
      v < version_for("2.0.0") ? "opscode-manage" : "chef-manage"
    end
    ctl_command do |v|
      v < version_for("2.0.0") ? "opscode-manage-ctl" : "chef-manage-ctl"
    end
    config_file do |v|
      if v < version_for("2.0.0")
        "/etc/opscode-manage/manage.rb"
      else
        "/etc/chef-manage/manage.rb"
      end
    end
  end

  product "marketplace" do
    product_name "Chef Cloud Marketplace addon"
    package_name "chef-marketplace"
    ctl_command "chef-marketplace-ctl"
    config_file "/etc/chef-marketplace/marketplace.rb"
  end

  product "omnibus-toolchain" do
    product_name "Omnibus Toolchain"
    package_name "omnibus-toolchain"
  end

  product "private-chef" do
    product_name "Enterprise Chef (legacy)"
    package_name "private-chef"
    ctl_command "private-chef-ctl"
    config_file "/etc/opscode/private-chef.rb"
  end

  product "push-jobs-client" do
    product_name "Chef Push Server"
    package_name do |v|
      v < version_for("1.3.0") ? "opscode-push-jobs-client" : "push-jobs-client"
    end
  end

  product "push-jobs-server" do
    product_name "Chef Push Server"
    package_name "opscode-push-jobs-server"
    ctl_command "opscode-push-jobs-server-ctl"
    config_file "/etc/opscode-push-jobs-server/opscode-push-jobs-server.rb"
  end

  product "reporting" do
    product_name "Chef Server Reporting addon"
    package_name "opscode-reporting"
    ctl_command "opscode-reporting-ctl"
    config_file "/etc/opscode-reporting/opscode-reporting.rb"
  end

  product "supermarket" do
    product_name "Supermarket"
    package_name "supermarket"
    ctl_command "supermarket-ctl"
    config_file "/etc/supermarket/supermarket.json"
  end

  product "sync" do
    product_name "Chef Server Replication addon"
    package_name "chef-sync"
    ctl_command "chef-sync-ctl"
    config_file "/etc/chef-sync/chef-sync.rb"
  end
end
