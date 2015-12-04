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

require "spec_helper"
require "mixlib/install/product"

context "Mixlib::Install::Product" do
  context "for product_name when using strings" do
    let(:product) {
      Mixlib::Install::Product.new do
        product_name "test-product"
      end
    }

    it "accepts and returns the value correctly" do
      expect(product.product_name).to eq("test-product")
    end

    it "returns nil for unset properties" do
      expect(product.package_name).to eq(nil)
    end

    it "errors for unexisting properties" do
      expect { product.address }.to raise_error(StandardError)
    end
  end

  context "for package_name when using block" do
    let(:product) {
      Mixlib::Install::Product.new do
        package_name do |version|
          "my-version-#{version}"
        end
      end
    }

    it "accepts and returns the value correctly without a version" do
      expect(product.package_name).to eq("my-version-")
    end

    it "accepts and returns the value correctly with a version" do
      product.version("11.0.0")
      expect(product.package_name).to eq("my-version-11.0.0")
    end

    it "returns nil for unset properties" do
      expect(product.product_name).to eq(nil)
    end

    it "errors for unexisting properties" do
      expect { product.address }.to raise_error(StandardError)
    end
  end

  context "for package_name when using block and string" do
    let(:product) {
      Mixlib::Install::Product.new do
        package_name "my-name" do |version|
          "my-version-#{version}"
        end
      end
    }

    it "should error" do
      expect { product }.to raise_error(StandardError)
    end
  end

  it "has version_for defined" do
    expect(Mixlib::Install::Product.new {}).to respond_to(:version_for)
  end

  it "has the DSL methods for all required properties" do
    expect(Mixlib::Install::Product::DSL_PROPERTIES).to include(:product_name)
    expect(Mixlib::Install::Product::DSL_PROPERTIES).to include(:package_name)
    expect(Mixlib::Install::Product::DSL_PROPERTIES).to include(:ctl_command)
    expect(Mixlib::Install::Product::DSL_PROPERTIES).to include(:config_file)
  end
end

context "PRODUCT_MATRIX" do
  let(:package_name) do
    PRODUCT_MATRIX.lookup(product_name, version).package_name
  end

  let(:ctl_command) do
    PRODUCT_MATRIX.lookup(product_name, version).ctl_command
  end

  CHEF_PRODUCTS = ["chef", "chefdk", "chef-server", "manage", "chef-ha",
                   "reporting", "supermarket", "chef-marketplace", "chef-sync",
                   "delivery", "delivery-cli", "analytics", "compliance",
                   "push-server", "push-client", "private-chef"]

  it "has entries for all #{CHEF_PRODUCTS.length} products" do
    CHEF_PRODUCTS.each do |p|
      expect(PRODUCT_MATRIX.lookup(p).product_name).to be_a(String)
    end
  end

  it "returns nil for unset parameters" do
    expect(PRODUCT_MATRIX.lookup("chef").ctl_command).to be_nil
  end

  context "for chef-server" do
    let(:product_name) { "chef-server" }

    context "for version > 12.0.0" do
      let(:version) { "12.0.5" }

      it "should return correct package_name" do
        expect(package_name).to eq("chef-server-core")
      end
    end

    context "for latest" do
      let(:version) { :latest }

      it "should return correct package_name" do
        expect(package_name).to eq("chef-server-core")
      end
    end

    context "for < 12.0.0, > 11.0.0" do
      let(:version) { "11.5.0" }

      it "should return correct package_name" do
        expect(package_name).to eq("chef-server")
      end
    end
  end

  context "for manage" do
    let(:product_name) { "manage" }

    context "for version > 2.0.0" do
      let(:version) { "2.0.5" }

      it "should return correct package_name" do
        expect(package_name).to eq("chef-manage")
      end

      it "should return correct ctl_command" do
        expect(ctl_command).to eq("chef-manage-ctl")
      end
    end

    context "for latest" do
      let(:version) { :latest }

      it "should return correct package_name" do
        expect(package_name).to eq("chef-manage")
      end

      it "should return correct ctl_command" do
        expect(ctl_command).to eq("chef-manage-ctl")
      end
    end

    context "for < 2.0.0" do
      let(:version) { "1.5.0" }

      it "should return correct package_name" do
        expect(package_name).to eq("opscode-manage")
      end

      it "should return correct ctl_command" do
        expect(ctl_command).to eq("opscode-manage-ctl")
      end
    end
  end

  context "for push-server" do
    let(:product_name) { "push-server" }

    context "for latest" do
      let(:version) { :latest }

      it "should return correct package_name" do
        expect(package_name).to eq("opscode-push-jobs-server")
      end

      it "should return correct ctl_command" do
        expect(ctl_command).to eq("opscode-push-jobs-server-ctl")
      end
    end

    context "for < 2.0.0" do
      let(:version) { "1.5.0" }

      it "should return correct package_name" do
        expect(package_name).to eq("opscode-push-jobs-server")
      end

      it "should return correct ctl_command" do
        expect(ctl_command).to eq("opscode-push-jobs-server-ctl")
      end
    end
  end

  context "for push-client" do
    let(:product_name) { "push-client" }

    context "for version > 1.3.0" do
      let(:version) { "1.3.5" }

      it "should return correct package_name" do
        expect(package_name).to eq("push-jobs-client")
      end
    end

    context "for latest" do
      let(:version) { :latest }

      it "should return correct package_name" do
        expect(package_name).to eq("push-jobs-client")
      end
    end

    context "for < 1.3.0" do
      let(:version) { "1.2.0" }

      it "should return correct package_name" do
        expect(package_name).to eq("opscode-push-jobs-client")
      end
    end
  end
end
