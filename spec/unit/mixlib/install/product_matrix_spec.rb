#
# Copyright:: Copyright (c) 2015-2018 Chef Software, Inc.
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

require "spec_helper"
require "mixlib/install/product_matrix"

describe Mixlib::Install::ProductMatrix do
  describe "#initialize" do
    it "creates a new ProductMatrix instance" do
      matrix = described_class.new {}
      expect(matrix).to be_a(described_class)
    end

    it "accepts a block for configuration" do
      matrix = described_class.new do
        product "test-product" do
          product_name "Test Product"
        end
      end

      expect(matrix).to be_a(described_class)
    end
  end

  describe "#product" do
    let(:matrix) do
      described_class.new do
        product "test-product" do
          product_name "Test Product"
          package_name "test-package"
        end
      end
    end

    it "defines a new product in the matrix" do
      expect(matrix.lookup("test-product")).not_to be_nil
      expect(matrix.lookup("test-product").product_name).to eq("Test Product")
    end
  end

  describe "#lookup" do
    context "with existing product" do
      it "returns the product for chef" do
        product = PRODUCT_MATRIX.lookup("chef")
        expect(product).not_to be_nil
        expect(product.product_name).to eq("Chef Infra Client")
      end

      it "returns the product for chef-server" do
        product = PRODUCT_MATRIX.lookup("chef-server")
        expect(product).not_to be_nil
        expect(product.product_name).to eq("Chef Infra Server")
      end

      it "returns the product for chef-ice" do
        product = PRODUCT_MATRIX.lookup("chef-ice")
        expect(product).not_to be_nil
        expect(product.product_name).to eq("Chef Infra Client Enterprise")
      end
    end

    context "with non-existing product" do
      it "returns nil for unknown product" do
        expect(PRODUCT_MATRIX.lookup("non-existing-product")).to be_nil
      end
    end

    context "with version parameter" do
      it "returns product with version context" do
        product = PRODUCT_MATRIX.lookup("chef", "17.0.0")
        expect(product).not_to be_nil
      end
    end
  end

  describe "#products" do
    it "returns an array of all product keys" do
      products = PRODUCT_MATRIX.products
      expect(products).to be_an(Array)
      expect(products).to include("chef")
      expect(products).to include("chef-server")
      expect(products).to include("chef-ice")
      expect(products).to include("automate")
    end

    it "does not include duplicate products" do
      products = PRODUCT_MATRIX.products
      expect(products.uniq.size).to eq(products.size)
    end
  end

  describe "#products_available_on_downloads_site" do
    it "returns products available on downloads site" do
      products = PRODUCT_MATRIX.products_available_on_downloads_site
      expect(products).to be_a(Hash)
      expect(products.keys).to include("chef")
      expect(products.keys).to include("chef-server")
    end

    it "does not include products with :not_available downloads URL" do
      products = PRODUCT_MATRIX.products_available_on_downloads_site
      # Products with downloads_product_page_url :not_available should not be included
      expect(products.keys).not_to include("angry-omnibus-toolchain")
    end
  end

  describe "product attributes" do
    context "for chef product" do
      let(:chef_product) { PRODUCT_MATRIX.lookup("chef") }

      it "has correct product_name" do
        expect(chef_product.product_name).to eq("Chef Infra Client")
      end

      it "has correct package_name" do
        expect(chef_product.package_name).to eq("chef")
      end

      it "does not have ctl_command" do
        expect(chef_product.ctl_command).to be_nil
      end

      it "has correct downloads_product_page_url" do
        expect(chef_product.downloads_product_page_url).to eq("https://downloads.chef.io/chef")
      end

      it "has correct github_repo" do
        expect(chef_product.github_repo).to eq("chef/chef")
      end
    end

    context "for chef-ice product" do
      let(:chef_ice_product) { PRODUCT_MATRIX.lookup("chef-ice") }

      it "has correct product_name" do
        expect(chef_ice_product.product_name).to eq("Chef Infra Client Enterprise")
      end

      it "has correct package_name" do
        expect(chef_ice_product.package_name).to eq("chef-ice")
      end
    end

    context "for chef-server product" do
      let(:chef_server_product) { PRODUCT_MATRIX.lookup("chef-server") }

      it "has correct product_name" do
        expect(chef_server_product.product_name).to eq("Chef Infra Server")
      end

      it "has correct omnibus_project" do
        expect(chef_server_product.omnibus_project).to eq("chef-server")
      end

      it "has correct ctl_command" do
        expect(chef_server_product.ctl_command).to eq("chef-server-ctl")
      end

      it "has versioned package_name" do
        # Should be chef-server-core for most versions
        expect(chef_server_product.package_name).to be_a(String)
      end
    end

    context "for automate product" do
      let(:automate_product) { PRODUCT_MATRIX.lookup("automate") }

      it "has correct product_name" do
        expect(automate_product.product_name).to eq("Chef Automate")
      end

      it "has versioned package_name" do
        # Should return delivery for older versions, automate for newer
        expect(automate_product.package_name).to be_a(String)
      end

      it "has versioned ctl_command" do
        # Should return delivery-ctl for older versions, automate-ctl for newer
        expect(automate_product.ctl_command).to be_a(String)
      end

      it "has config_file" do
        expect(automate_product.config_file).to eq("/etc/delivery/delivery.rb")
      end
    end
  end

  describe "version-specific attributes" do
    context "when package_name is a proc" do
      let(:automate_product) { PRODUCT_MATRIX.lookup("automate") }

      it "evaluates package_name based on version" do
        # For versions < 0.7.0, should be "delivery"
        # For versions >= 0.7.0, should be "automate"
        expect(automate_product.package_name).to be_a(String)
      end
    end

    context "when ctl_command is a proc" do
      let(:automate_product) { PRODUCT_MATRIX.lookup("automate") }

      it "evaluates ctl_command based on version" do
        expect(automate_product.ctl_command).to be_a(String)
      end
    end
  end

  describe "#lookup as accessor" do
    it "can be used to retrieve products" do
      chef_product = PRODUCT_MATRIX.lookup("chef")
      expect(chef_product).not_to be_nil
      expect(chef_product.product_name).to eq("Chef Infra Client")
    end
  end

  describe "edge cases" do
    context "with nil product key" do
      it "returns nil" do
        expect(PRODUCT_MATRIX.lookup(nil)).to be_nil
      end
    end

    context "with empty string product key" do
      it "returns nil" do
        expect(PRODUCT_MATRIX.lookup("")).to be_nil
      end
    end
  end
end
