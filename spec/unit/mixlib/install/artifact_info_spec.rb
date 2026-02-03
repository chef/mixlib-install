#
# Author:: Patrick Wright (<patrick@chef.io>)
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
require "mixlib/install/artifact_info"

describe Mixlib::Install::ArtifactInfo do
  let(:artifact_data) do
    {
      architecture: "x86_64",
      license: "Apache-2.0",
      license_content: "Apache License 2.0...",
      md5: "1234567890abcdef",
      platform: "ubuntu",
      platform_version: "20.04",
      product_description: "Chef Infra Client",
      product_name: "chef",
      sha1: "abcdef1234567890",
      sha256: "1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef",
      software_dependencies: [],
      url: "https://packages.chef.io/files/stable/chef/17.0.0/ubuntu/20.04/chef_17.0.0-1_amd64.deb",
      version: "17.0.0",
    }
  end

  describe "#initialize" do
    it "creates an ArtifactInfo instance with all attributes" do
      artifact = described_class.new(artifact_data)

      expect(artifact.architecture).to eq("x86_64")
      expect(artifact.license).to eq("Apache-2.0")
      expect(artifact.license_content).to eq("Apache License 2.0...")
      expect(artifact.md5).to eq("1234567890abcdef")
      expect(artifact.platform).to eq("ubuntu")
      expect(artifact.platform_version).to eq("20.04")
      expect(artifact.product_description).to eq("Chef Infra Client")
      expect(artifact.product_name).to eq("chef")
      expect(artifact.sha1).to eq("abcdef1234567890")
      expect(artifact.sha256).to eq("1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef")
      expect(artifact.software_dependencies).to eq([])
      expect(artifact.url).to eq("https://packages.chef.io/files/stable/chef/17.0.0/ubuntu/20.04/chef_17.0.0-1_amd64.deb")
      expect(artifact.version).to eq("17.0.0")
    end

    it "handles partial data" do
      partial_data = {
        platform: "centos",
        platform_version: "7",
        architecture: "x86_64",
        url: "https://example.com/package.rpm",
        version: "1.0.0",
      }

      artifact = described_class.new(partial_data)

      expect(artifact.platform).to eq("centos")
      expect(artifact.platform_version).to eq("7")
      expect(artifact.architecture).to eq("x86_64")
      expect(artifact.url).to eq("https://example.com/package.rpm")
      expect(artifact.version).to eq("1.0.0")
      expect(artifact.sha256).to be_nil
    end
  end

  describe ".from_json" do
    let(:json_data) do
      '{"url":"https://packages.chef.io/files/stable/chef/17.0.0/ubuntu/20.04/chef_17.0.0-1_amd64.deb","sha256":"1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef","version":"17.0.0"}'
    end

    let(:platform_info) do
      {
        platform: "ubuntu",
        platform_version: "20.04",
        architecture: "x86_64",
      }
    end

    it "creates an ArtifactInfo from JSON and platform info" do
      artifact = described_class.from_json(json_data, platform_info)

      expect(artifact.url).to eq("https://packages.chef.io/files/stable/chef/17.0.0/ubuntu/20.04/chef_17.0.0-1_amd64.deb")
      expect(artifact.sha256).to eq("1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef")
      expect(artifact.version).to eq("17.0.0")
      expect(artifact.platform).to eq("ubuntu")
      expect(artifact.platform_version).to eq("20.04")
      expect(artifact.architecture).to eq("x86_64")
    end
  end

  describe ".from_metadata_map" do
    let(:metadata_json) do
      '{
        "ubuntu": {
          "20.04": {
            "x86_64": {
              "url": "https://packages.chef.io/files/stable/chef/17.0.0/ubuntu/20.04/chef_17.0.0-1_amd64.deb",
              "sha256": "1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef",
              "version": "17.0.0"
            }
          },
          "18.04": {
            "x86_64": {
              "url": "https://packages.chef.io/files/stable/chef/17.0.0/ubuntu/18.04/chef_17.0.0-1_amd64.deb",
              "sha256": "abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890",
              "version": "17.0.0"
            }
          }
        },
        "centos": {
          "7": {
            "x86_64": {
              "url": "https://packages.chef.io/files/stable/chef/17.0.0/el/7/chef-17.0.0-1.el7.x86_64.rpm",
              "sha256": "fedcba0987654321fedcba0987654321fedcba0987654321fedcba0987654321",
              "version": "17.0.0"
            }
          }
        }
      }'
    end

    it "creates an array of ArtifactInfo from metadata map" do
      artifacts = described_class.from_metadata_map(metadata_json)

      expect(artifacts).to be_an(Array)
      expect(artifacts.size).to eq(3)

      # Check ubuntu 20.04 artifact
      ubuntu_20_artifact = artifacts.find { |a| a.platform == :ubuntu && a.platform_version == :"20.04" }
      expect(ubuntu_20_artifact).not_to be_nil
      expect(ubuntu_20_artifact.architecture).to eq(:x86_64)
      expect(ubuntu_20_artifact.url).to include("ubuntu/20.04")
      expect(ubuntu_20_artifact.version).to eq("17.0.0")

      # Check ubuntu 18.04 artifact
      ubuntu_18_artifact = artifacts.find { |a| a.platform == :ubuntu && a.platform_version == :"18.04" }
      expect(ubuntu_18_artifact).not_to be_nil
      expect(ubuntu_18_artifact.architecture).to eq(:x86_64)
      expect(ubuntu_18_artifact.url).to include("ubuntu/18.04")

      # Check centos 7 artifact
      centos_artifact = artifacts.find { |a| a.platform == :centos }
      expect(centos_artifact).not_to be_nil
      expect(centos_artifact.platform_version).to eq(:"7")
      expect(centos_artifact.architecture).to eq(:x86_64)
      expect(centos_artifact.url).to include("el/7")
    end
  end

  describe "#to_hash" do
    it "converts ArtifactInfo to hash" do
      artifact = described_class.new(artifact_data)
      hash = artifact.to_hash

      expect(hash).to be_a(Hash)
      expect(hash[:platform]).to eq("ubuntu")
      expect(hash[:platform_version]).to eq("20.04")
      expect(hash[:architecture]).to eq("x86_64")
      expect(hash[:version]).to eq("17.0.0")
      expect(hash[:url]).to eq("https://packages.chef.io/files/stable/chef/17.0.0/ubuntu/20.04/chef_17.0.0-1_amd64.deb")
      expect(hash[:sha256]).to eq("1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef")
    end

    it "includes all attributes in the hash" do
      artifact = described_class.new(artifact_data)
      hash = artifact.to_hash

      described_class::ATTRIBUTES.each do |attribute|
        expect(hash.key?(attribute.to_sym)).to be true
      end
    end
  end

  describe "#clone_with" do
    let(:original_artifact) { described_class.new(artifact_data) }

    it "creates a new artifact with merged data" do
      new_data = { platform_version: "22.04", architecture: "aarch64" }
      cloned = original_artifact.clone_with(new_data)

      expect(cloned).to be_a(described_class)
      expect(cloned.platform_version).to eq("22.04")
      expect(cloned.architecture).to eq("aarch64")
      # Original data should be preserved
      expect(cloned.platform).to eq("ubuntu")
      expect(cloned.version).to eq("17.0.0")
    end

    it "does not modify the original artifact" do
      new_data = { platform_version: "22.04" }
      original_version = original_artifact.platform_version

      original_artifact.clone_with(new_data)

      expect(original_artifact.platform_version).to eq(original_version)
    end
  end

  describe "#appx_artifact?" do
    context "when url ends with .appx" do
      let(:appx_data) do
        artifact_data.merge(url: "https://packages.chef.io/files/stable/chef/17.0.0/windows/chef-17.0.0-1-x64.appx")
      end

      it "returns true" do
        artifact = described_class.new(appx_data)
        expect(artifact.appx_artifact?).to be true
      end
    end

    context "when url does not end with .appx" do
      it "returns false for .deb" do
        artifact = described_class.new(artifact_data)
        expect(artifact.appx_artifact?).to be false
      end

      it "returns false for .rpm" do
        rpm_data = artifact_data.merge(url: "https://packages.chef.io/files/stable/chef/17.0.0/el/7/chef-17.0.0-1.el7.x86_64.rpm")
        artifact = described_class.new(rpm_data)
        expect(artifact.appx_artifact?).to be false
      end

      it "returns false for .msi" do
        msi_data = artifact_data.merge(url: "https://packages.chef.io/files/stable/chef/17.0.0/windows/2016/chef-client-17.0.0-1-x64.msi")
        artifact = described_class.new(msi_data)
        expect(artifact.appx_artifact?).to be false
      end

      it "returns false for .pkg" do
        pkg_data = artifact_data.merge(url: "https://packages.chef.io/files/stable/chef/17.0.0/mac_os_x/10.15/chef-17.0.0-1.dmg")
        artifact = described_class.new(pkg_data)
        expect(artifact.appx_artifact?).to be false
      end
    end
  end

  describe "attribute readers" do
    it "provides readers for all ATTRIBUTES" do
      artifact = described_class.new(artifact_data)

      described_class::ATTRIBUTES.each do |attribute|
        expect(artifact).to respond_to(attribute.to_sym)
      end
    end
  end
end
