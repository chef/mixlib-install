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
require "mixlib/install/product"

context "Mixlib::Install::Product" do
  context "for product_name when using strings" do
    let(:product) do
      Mixlib::Install::Product.new("product") do
        product_name "test-product"
      end
    end

    it "accepts and returns the value correctly" do
      expect(product.product_key).to eq("product")
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
    let(:product) do
      Mixlib::Install::Product.new("product") do
        package_name do |version|
          "my-version-#{version}"
        end
      end
    end

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
    let(:product) do
      Mixlib::Install::Product.new("product") do
        package_name "my-name" do |version|
          "my-version-#{version}"
        end
      end
    end

    it "should error" do
      expect { product }.to raise_error(StandardError)
    end
  end

  it "has version_for defined" do
    expect(Mixlib::Install::Product.new("product") {}).to respond_to(:version_for)
  end

  it "has the DSL methods for all required properties" do
    expect(Mixlib::Install::Product::DSL_PROPERTIES).to include(:product_key)
    expect(Mixlib::Install::Product::DSL_PROPERTIES).to include(:product_name)
    expect(Mixlib::Install::Product::DSL_PROPERTIES).to include(:package_name)
    expect(Mixlib::Install::Product::DSL_PROPERTIES).to include(:ctl_command)
    expect(Mixlib::Install::Product::DSL_PROPERTIES).to include(:config_file)
    expect(Mixlib::Install::Product::DSL_PROPERTIES).to include(:install_path)
    expect(Mixlib::Install::Product::DSL_PROPERTIES).to include(:omnibus_project)
    expect(Mixlib::Install::Product::DSL_PROPERTIES).to include(:github_repo)
    expect(Mixlib::Install::Product::DSL_PROPERTIES).to include(:downloads_product_page_url)
  end
end

context "PRODUCT_MATRIX" do
  let(:product_key) do
    PRODUCT_MATRIX.lookup(product_name, version).product_key
  end

  let(:package_name) do
    PRODUCT_MATRIX.lookup(product_name, version).package_name
  end

  let(:omnibus_project) do
    PRODUCT_MATRIX.lookup(product_name, version).omnibus_project
  end

  let(:ctl_command) do
    PRODUCT_MATRIX.lookup(product_name, version).ctl_command
  end

  let(:config_file) do
    PRODUCT_MATRIX.lookup(product_name, version).config_file
  end

  let(:install_path) do
    PRODUCT_MATRIX.lookup(product_name, version).install_path
  end

  let(:github_repo) do
    PRODUCT_MATRIX.lookup(product_name, version).github_repo
  end

  let(:downloads_product_page_url) do
    PRODUCT_MATRIX.lookup(product_name, version).downloads_product_page_url
  end

  CHEF_PRODUCTS = %w{
    analytics
    angry-omnibus-toolchain
    angrychef
    automate
    chef
    chef-backend
    chef-server
    chef-server-ha-provisioning
    chef-workstation
    chefdk
    compliance
    delivery
    ha
    harmony
    inspec
    manage
    marketplace
    omnibus-toolchain
    private-chef
    push-jobs-client
    push-jobs-server
    reporting
    supermarket
    sync
  }

  it "has entries for all #{CHEF_PRODUCTS.length} products" do
    expect(PRODUCT_MATRIX.products).to eq CHEF_PRODUCTS
  end

  it "can lookup entries for all #{CHEF_PRODUCTS.length} products" do
    CHEF_PRODUCTS.each do |p|
      expect(PRODUCT_MATRIX.lookup(p).product_name).to be_a(String)
    end
  end

  it "returns nil when looking up a non-existent product" do
    expect(PRODUCT_MATRIX.lookup("no-such-project")).to be_nil
  end

  it "returns nil for unset parameters" do
    expect(PRODUCT_MATRIX.lookup("chef").ctl_command).to be_nil
  end

  it "defaults downloads_product_page_url using product_key by default" do
    expect(PRODUCT_MATRIX.lookup("chef").downloads_product_page_url).to eq("https://downloads.chef.io/chef")
  end

  it "defaults github_repo using product_key by default" do
    expect(PRODUCT_MATRIX.lookup("chef").github_repo).to eq("chef/chef")
  end

  context "products available on downloads site" do
    let(:downloads_site_products) { PRODUCT_MATRIX.products_available_on_downloads_site }

    it "includes automate" do
      expect(downloads_site_products["automate"].downloads_product_page_url).to eq "https://downloads.chef.io/automate"
    end

    it "includes delivery" do
      expect(downloads_site_products["delivery"].downloads_product_page_url).to eq "https://downloads.chef.io/automate"
    end

    it "excludes sync" do
      expect(downloads_site_products["sync"]).to be_nil
    end
  end

  context "for chef-server" do
    let(:product_name) { "chef-server" }

    it "should return only one known omnibus project name" do
      expect(PRODUCT_MATRIX.lookup("chef-server").known_omnibus_projects).to eq ["chef-server"]
    end

    context "for version > 12.0.0" do
      let(:version) { "12.0.5" }

      it "should return correct package_name" do
        expect(package_name).to eq("chef-server-core")
      end

      it "should return correct install_path" do
        expect(install_path).to eq("/opt/opscode")
      end
    end

    context "for latest" do
      let(:version) { :latest }

      it "should return correct package_name" do
        expect(package_name).to eq("chef-server-core")
      end

      it "should return correct install_path" do
        expect(install_path).to eq("/opt/opscode")
      end
    end

    context "for < 12.0.0, > 11.0.0" do
      let(:version) { "11.5.0" }

      it "should return correct package_name" do
        expect(package_name).to eq("chef-server")
      end

      it "should return correct install_path" do
        expect(install_path).to eq("/opt/chef-server")
      end
    end
  end

  context "for manage" do
    let(:product_name) { "manage" }

    it "should return both known omnibus project name" do
      expect(PRODUCT_MATRIX.lookup("manage").known_omnibus_projects).to eq ["opscode-manage", "chef-manage"]
    end

    context "for version > 2.0.0" do
      let(:version) { "2.0.5" }

      it "should return correct package_name" do
        expect(package_name).to eq("chef-manage")
      end

      it "should return correct ctl_command" do
        expect(ctl_command).to eq("chef-manage-ctl")
      end

      it "should return correct config_file" do
        expect(config_file).to eq("/etc/chef-manage/manage.rb")
      end

      it "should return correct install_path" do
        expect(install_path).to eq("/opt/chef-manage")
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

      it "should return correct config_file" do
        expect(config_file).to eq("/etc/chef-manage/manage.rb")
      end

      it "should return correct install_path" do
        expect(install_path).to eq("/opt/chef-manage")
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

      it "should return correct config_file" do
        expect(config_file).to eq("/etc/opscode-manage/manage.rb")
      end

      it "should return correct install_path" do
        expect(install_path).to eq("/opt/opscode-manage")
      end
    end
  end

  context "for push-jobs-server" do
    let(:product_name) { "push-jobs-server" }

    it "should return only one known omnibus project name" do
      expect(PRODUCT_MATRIX.lookup("push-jobs-server").known_omnibus_projects).to eq ["opscode-push-jobs-server"]
    end

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

  context "for push-jobs-client" do
    let(:product_name) { "push-jobs-client" }

    it "should return both known omnibus project name" do
      expect(PRODUCT_MATRIX.lookup("push-jobs-client").known_omnibus_projects).to eq ["opscode-push-jobs-client", "push-jobs-client"]
    end

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

  shared_examples_for "automate and delivery products" do
    it "should return known omnibus project names" do
      expect(PRODUCT_MATRIX.lookup(product_name).known_omnibus_projects).to eq %w{delivery automate}
    end

    context "for version < 0.7.0" do
      let(:version) { "0.6.0" }

      it "should return correct package_name" do
        expect(package_name).to eq("delivery")
      end

      it "should return correct omnibus_project" do
        expect(omnibus_project).to eq("delivery")
      end

      it "should return correct ctl_command" do
        expect(ctl_command).to eq("delivery-ctl")
      end
    end

    context "for 0.7" do
      let(:version) { "0.7.0" }

      it "should return correct package_name" do
        expect(package_name).to eq("automate")
      end

      it "should return correct omnibus_project" do
        expect(omnibus_project).to eq("automate")
      end

      it "should return correct ctl_command" do
        expect(ctl_command).to eq("automate-ctl")
      end
    end

    context "for latest" do
      let(:version) { :latest }

      it "should return correct package_name" do
        expect(package_name).to eq("automate")
      end

      it "should return correct omnibus_project" do
        expect(omnibus_project).to eq("automate")
      end

      it "should return correct ctl_command" do
        expect(ctl_command).to eq("automate-ctl")
      end
    end
  end

  context "for automate" do
    let(:product_name) { "automate" }

    it_behaves_like "automate and delivery products"
  end

  context "for delivery" do
    let(:product_name) { "delivery" }

    it_behaves_like "automate and delivery products"
  end
end
