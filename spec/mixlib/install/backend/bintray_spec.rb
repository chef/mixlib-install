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

require "spec_helper"
require "mixlib/install/options"
require "mixlib/install/backend/bintray"

context "Mixlib::Install::Backend::Bintray", :vcr do
  let(:channel) { nil }
  let(:product_name) { nil }
  let(:product_version) { nil }
  let(:platform) { nil }
  let(:platform_version) { nil }
  let(:architecture) { nil }
  let(:pv_compat) { nil }

  let(:options) do
    {}.tap do |opt|
      opt[:product_name] = product_name
      opt[:product_version] = product_version
      opt[:channel] = channel
      opt[:platform_version_compatibility_mode] = pv_compat if pv_compat
      if platform
        opt[:platform] = platform
        opt[:platform_version] = platform_version
        opt[:architecture] = architecture
      end
    end
  end

  let(:mixlib_options) { Mixlib::Install::Options.new(options) }
  let(:bintray) { Mixlib::Install::Backend::Bintray.new(mixlib_options) }
  let(:artifact_info) { bintray.info }

  context "for chef/stable with :latest version" do
    let(:channel) { :stable }
    let(:product_name) { "chef" }
    let(:product_version) { :latest }

    it "returns all artifacts" do
      expect(artifact_info.size).to be > 1
    end

    context "with platform info" do
      let(:platform) { "ubuntu" }
      let(:platform_version) { "14.04" }
      let(:architecture) { "x86_64" }

      it "returns a single artifact with correct info" do
        expect(artifact_info).to be_a Mixlib::Install::ArtifactInfo
        require "pry"; expect(artifact_info.version).to eq "12.12.15"
        expect(artifact_info.platform).to eq "ubuntu"
        expect(artifact_info.platform_version).to eq "14.04"
        expect(artifact_info.architecture).to eq "x86_64"
        expect(artifact_info.sha256).to eq "d64a029bc5402e2c2e2e1ad479e8b49b3dc7599a9d50ea3cefe4149b070582be"
        expect(artifact_info.url).to eq "https://packages.chef.io/stable/ubuntu/14.04/chef_12.12.15-1_amd64.deb"
      end
    end
  end

  context "for a product without native 64-bit builds" do
    let(:channel) { :stable }
    let(:product_name) { "chefdk" }
    let(:product_version) { :latest }
    let(:platform) { "windows" }
    let(:platform_version) { "2012r2" }
    let(:architecture) { "x86_64" }

    it "returns 32 bit package for 64 bit" do
      expect(artifact_info).to be_a Mixlib::Install::ArtifactInfo
      expect(artifact_info.url).to match("x86")
    end
  end

  context "for a product with native 64-bit builds" do
    let(:channel) { :current }
    let(:product_name) { "chef" }
    let(:product_version) { :latest }
    let(:platform) { "windows" }
    let(:platform_version) { "2012r2" }
    let(:architecture) { "x86_64" }

    it "returns 64 bit package for 64 bit" do
      expect(artifact_info).to be_a Mixlib::Install::ArtifactInfo
      expect(artifact_info.url).to match("x64")
    end
  end

  context "architecture extraction" do
    let(:channel) { :stable }
    let(:product_name) { "chef" }
    let(:product_version) { :latest }

    it "extracts the architecture from file name correctly" do
      {
        "x86_64" => [
          "chef_12.8.1-1_amd64.deb",
          "chef_12.8.1-1_x64.deb",
          "chef_12.8.1-1_x86_64.deb",
          "chef_12.8.1-1.dmg",
          "chef_12.8.1-1.sh",
        ],
        "i386" => [
          "chef_12.8.1-1_i386.deb",
          "chef_12.8.1-1_i686.deb",
          "chef_12.8.1-1_x86.deb",
          "chef_12.8.1-1_i86pc.deb",
          "chef_12.8.1-1.msi",
          "chef-11.8.2-1.solaris2.5.10.solaris",
        ],
        "powerpc" => [
          "chef-12.8.1-1.powerpc.bff",
        ],
        "sparc" => [
          "chef-12.8.1-1.sparc.solaris",
          "chef-12.8.1-1.sun4u.solaris",
          "chef-12.8.1-1.sun4v.solaris",
          "chef-11.8.2-1.solaris2.5.9.solaris",
        ],
        "ppc64" => [
          "chef-12.8.1-1.ppc64.bff",
        ],
        "ppc64le" => [
          "chef-12.8.1-1.ppc64le.bff",
          "chef-12.8.1-1.ppc64el.bff",
        ],
      }.each do |arch, filenames|
        filenames.each do |filename|
          expect(bintray.parse_architecture_from_file_name(filename)).to eq(arch)
        end
      end
    end
  end

  context "for a version with unique solaris publishing values" do
    let(:channel) { :stable }
    let(:product_name) { "chef" }
    let(:product_version) { "12.4.1" }
    let(:platform) { "solaris2" }
    let(:platform_version) { "5.10" }
    let(:architecture) { "sparc" }

    it "finds an artifact" do
      expect(artifact_info).to be_a Mixlib::Install::ArtifactInfo
      expect(artifact_info.version).to eq "12.4.1"
      expect(artifact_info.platform).to eq "solaris2"
      expect(artifact_info.platform_version).to eq "5.10"
      expect(artifact_info.architecture).to eq "sparc"
    end
  end

  context "for a version of ubuntu that is not added to our matrix" do
    let(:channel) { :stable }
    let(:product_name) { "delivery" }
    let(:product_version) { :latest }
    let(:platform) { "ubuntu" }
    let(:platform_version) { "15.04" }
    let(:architecture) { "x86_64" }

    it "can not find an artifact" do
      expect(artifact_info).to be_empty
    end

    context "when product_version compat mode is set" do
      let(:pv_compat) { true }

      it "finds an artifact" do
        expect(artifact_info).to be_a Mixlib::Install::ArtifactInfo
        expect(artifact_info.platform).to eq "ubuntu"
        expect(artifact_info.platform_version).to eq "14.04"
        expect(artifact_info.architecture).to eq "x86_64"
      end
    end
  end

  context "for a version of el that is not added to our matrix" do
    let(:channel) { :stable }
    let(:product_name) { "delivery" }
    let(:product_version) { :latest }
    let(:platform) { "el" }
    let(:platform_version) { "8" }
    let(:architecture) { "x86_64" }

    it "can not find an artifact" do
      expect(artifact_info).to be_empty
    end

    context "when product_version compat mode is set" do
      let(:pv_compat) { true }

      it "finds an artifact" do
        expect(artifact_info).to be_a Mixlib::Install::ArtifactInfo
        expect(artifact_info.platform).to eq "el"
        expect(artifact_info.platform_version).to eq "7"
        expect(artifact_info.architecture).to eq "x86_64"
      end
    end
  end

  context "for a missing version of a product" do
    let(:channel) { :current }
    let(:product_name) { "chef" }
    let(:product_version) { "99.99.99" }
    let(:platform) { "windows" }
    let(:platform_version) { "2012r2" }
    let(:architecture) { "x86_64" }

    it "raises an error" do
      expect { artifact_info }.to raise_error Mixlib::Install::Backend::Bintray::VersionNotFound
    end
  end

  context "for automate" do
    let(:channel) { :stable }
    let(:product_name) { "automate" }
    let(:product_version) { :latest }
    let(:platform) { "ubuntu" }
    let(:platform_version) { "14.04" }
    let(:architecture) { "x86_64" }

    it "uses product package name" do
      expect(bintray.info).to be_a Mixlib::Install::ArtifactInfo
      expect(bintray.info.url).to match "delivery"
    end
  end

  context "for compliance" do
    let(:channel) { :stable }
    let(:product_name) { "compliance" }
    let(:product_version) { :latest }
    let(:platform) { "ubuntu" }
    let(:platform_version) { "14.04" }
    let(:architecture) { "x86_64" }

    it "uses product package name" do
      expect(bintray.info).to be_a Mixlib::Install::ArtifactInfo
      expect(bintray.info.url).to match "chef-compliance"
    end
  end
end
