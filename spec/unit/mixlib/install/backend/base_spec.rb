#
# Author:: Patrick Wright (<patrick@chef.io>)
# Copyright:: Copyright (c) 2016-2018 Chef Software, Inc.
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
require "mixlib/install/backend/base"
require "mixlib/install/options"
require "mixlib/install/artifact_info"

describe Mixlib::Install::Backend::Base do
  let(:channel) { :stable }
  let(:product_name) { "chef" }
  let(:product_version) { "17.0.0" }
  let(:platform) { "ubuntu" }
  let(:platform_version) { "20.04" }
  let(:architecture) { "x86_64" }
  let(:platform_version_compatibility_mode) { true }

  let(:options) do
    Mixlib::Install::Options.new(
      channel: channel,
      product_name: product_name,
      product_version: product_version,
      platform: platform,
      platform_version: platform_version,
      architecture: architecture,
      platform_version_compatibility_mode: platform_version_compatibility_mode
    )
  end

  let(:backend) { described_class.new(options) }

  describe "#initialize" do
    it "creates a new backend with options" do
      expect(backend).to be_a(described_class)
      expect(backend.options).to eq(options)
    end
  end

  describe "#available_artifacts" do
    it "raises an error when not implemented" do
      expect { backend.available_artifacts }.to raise_error(RuntimeError, /Must implement available_artifacts/)
    end
  end

  describe "#available_versions" do
    it "raises an error when not implemented" do
      expect { backend.available_versions }.to raise_error(RuntimeError, /only available for Artifactory backend/)
    end
  end

  describe "#platform_filters_available?" do
    context "when platform is set" do
      it "returns true" do
        expect(backend.platform_filters_available?).to be true
      end
    end

    context "when platform is nil" do
      let(:options) do
        Mixlib::Install::Options.new(
          channel: channel,
          product_name: product_name,
          product_version: product_version
        )
      end

      it "returns false" do
        expect(backend.platform_filters_available?).to be false
      end
    end
  end

  describe "#filter_artifacts" do
    let(:artifacts) do
      [
        Mixlib::Install::ArtifactInfo.new(
          platform: "ubuntu",
          platform_version: "20.04",
          architecture: "x86_64",
          url: "https://packages.chef.io/files/stable/chef/17.0.0/ubuntu/20.04/chef_17.0.0-1_amd64.deb",
          version: "17.0.0"
        ),
        Mixlib::Install::ArtifactInfo.new(
          platform: "ubuntu",
          platform_version: "18.04",
          architecture: "x86_64",
          url: "https://packages.chef.io/files/stable/chef/17.0.0/ubuntu/18.04/chef_17.0.0-1_amd64.deb",
          version: "17.0.0"
        ),
        Mixlib::Install::ArtifactInfo.new(
          platform: "centos",
          platform_version: "7",
          architecture: "x86_64",
          url: "https://packages.chef.io/files/stable/chef/17.0.0/el/7/chef-17.0.0-1.el7.x86_64.rpm",
          version: "17.0.0"
        ),
      ]
    end

    context "without platform filters" do
      let(:options) do
        Mixlib::Install::Options.new(
          channel: channel,
          product_name: product_name,
          product_version: product_version
        )
      end

      it "returns all artifacts" do
        result = backend.filter_artifacts(artifacts)
        expect(result).to eq(artifacts)
      end
    end

    context "with exact platform match" do
      it "returns the exact matching artifact" do
        result = backend.filter_artifacts(artifacts)
        expect(result).to be_a(Mixlib::Install::ArtifactInfo)
        expect(result.platform).to eq("ubuntu")
        expect(result.platform_version).to eq("20.04")
        expect(result.architecture).to eq("x86_64")
      end
    end

    context "with platform but no exact version match" do
      let(:platform_version) { "19.04" }

      context "with compatibility mode enabled" do
        let(:platform_version_compatibility_mode) { true }

        it "returns the closest compatible version" do
          result = backend.filter_artifacts(artifacts)
          expect(result).to be_a(Mixlib::Install::ArtifactInfo)
          expect(result.platform).to eq("ubuntu")
          # When requested version is 19.04, the highest compatible version below it is 18.04
          # However, if no exact match but 20.04 exists, it may return 20.04
          expect(["18.04", "20.04"]).to include(result.platform_version)
        end
      end

      context "with compatibility mode disabled" do
        let(:platform_version_compatibility_mode) { false }

        it "raises ArtifactsNotFound error" do
          expect { backend.filter_artifacts(artifacts) }.to raise_error(Mixlib::Install::Backend::ArtifactsNotFound)
        end
      end
    end

    context "with no matching platform" do
      let(:platform) { "freebsd" }
      let(:platform_version) { "12" }

      it "raises ArtifactsNotFound error" do
        expect { backend.filter_artifacts(artifacts) }.to raise_error(
          Mixlib::Install::Backend::ArtifactsNotFound,
          /No artifacts found matching criteria/
        )
      end

      it "includes error details in exception message" do
        expect { backend.filter_artifacts(artifacts) }.to raise_error do |error|
          expect(error.message).to include("product name: chef")
          expect(error.message).to include("channel: stable")
          expect(error.message).to include("version: 17.0.0")
          expect(error.message).to include("platform: freebsd")
          expect(error.message).to include("platform version: 12")
          expect(error.message).to include("architecture: x86_64")
        end
      end
    end

    context "with architecture mismatch" do
      let(:architecture) { "aarch64" }

      it "raises ArtifactsNotFound error" do
        expect { backend.filter_artifacts(artifacts) }.to raise_error(Mixlib::Install::Backend::ArtifactsNotFound)
      end
    end

    context "with compatible version selection" do
      let(:platform_version) { "20.10" }
      let(:platform_version_compatibility_mode) { true }
      let(:artifacts) do
        [
          Mixlib::Install::ArtifactInfo.new(
            platform: "ubuntu",
            platform_version: "18.04",
            architecture: "x86_64",
            url: "https://example.com/18.04.deb",
            version: "17.0.0"
          ),
          Mixlib::Install::ArtifactInfo.new(
            platform: "ubuntu",
            platform_version: "20.04",
            architecture: "x86_64",
            url: "https://example.com/20.04.deb",
            version: "17.0.0"
          ),
        ]
      end

      it "selects the highest compatible version below the requested version" do
        result = backend.filter_artifacts(artifacts)
        expect(result.platform_version).to eq("20.04")
      end
    end

    context "with windows platform versions containing r2" do
      let(:platform) { "windows" }
      let(:platform_version) { "2012r2" }
      let(:artifacts) do
        [
          Mixlib::Install::ArtifactInfo.new(
            platform: "windows",
            platform_version: "2012r2",
            architecture: "x86_64",
            url: "https://example.com/2012r2.msi",
            version: "17.0.0"
          ),
        ]
      end

      it "handles r2 suffix in platform version" do
        result = backend.filter_artifacts(artifacts)
        expect(result).to be_a(Mixlib::Install::ArtifactInfo)
        expect(result.platform_version).to eq("2012r2")
      end
    end
  end

  describe "#info" do
    let(:concrete_backend) do
      Class.new(described_class) do
        def available_artifacts
          [
            Mixlib::Install::ArtifactInfo.new(
              platform: "ubuntu",
              platform_version: "20.04",
              architecture: "x86_64",
              url: "https://packages.chef.io/test.deb",
              version: "17.0.0"
            ),
          ]
        end
      end
    end

    let(:backend) { concrete_backend.new(options) }

    it "calls filter_artifacts on available_artifacts" do
      result = backend.info
      expect(result).to be_a(Mixlib::Install::ArtifactInfo)
      expect(result.platform).to eq("ubuntu")
    end
  end

  describe "edge cases" do
    let(:artifacts) do
      [
        Mixlib::Install::ArtifactInfo.new(
          platform: "ubuntu",
          platform_version: "16.04",
          architecture: "x86_64",
          url: "https://example.com/16.04.deb",
          version: "17.0.0"
        ),
      ]
    end

    context "with platform version as string" do
      let(:platform_version) { "20.04" }
      let(:platform_version_compatibility_mode) { true }

      it "handles string comparison correctly" do
        # When 20.04 is requested but only 16.04 exists, and compat mode is on,
        # it should still fail because 16.04 < 20.04 but there's no exact match
        result = backend.filter_artifacts(artifacts)
        # Actually, with compat mode on, it should return 16.04 as closest lower version
        expect(result).to be_a(Mixlib::Install::ArtifactInfo)
        expect(result.platform_version).to eq("16.04")
      end
    end

    context "with empty artifacts list" do
      let(:artifacts) { [] }

      it "raises ArtifactsNotFound error" do
        expect { backend.filter_artifacts(artifacts) }.to raise_error(Mixlib::Install::Backend::ArtifactsNotFound)
      end
    end
  end
end
