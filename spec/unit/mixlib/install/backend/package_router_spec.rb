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
require "mixlib/install/backend/package_router"
require "mixlib/install/version"

context "Mixlib::Install::Backend::PackageRouter all channels", :vcr do
  let(:channel) { nil }
  let(:product_name) { nil }
  let(:product_version) { nil }
  let(:platform) { nil }
  let(:platform_version) { nil }
  let(:architecture) { nil }
  let(:user_agent_headers) { nil }
  let(:pv_compat) { nil }
  let(:include_metadata) { nil }
  let(:license_id) { nil }

  let(:options) do
    {}.tap do |opt|
      opt[:product_name] = product_name
      opt[:product_version] = product_version
      opt[:channel] = channel
      opt[:platform_version_compatibility_mode] = pv_compat if pv_compat
      opt[:include_metadata] = include_metadata if include_metadata
      opt[:user_agent_headers] = user_agent_headers if user_agent_headers
      opt[:platform] = platform if platform
      opt[:platform_version] = platform_version if platform_version
      opt[:architecture] = architecture if architecture
      opt[:license_id] = license_id if license_id
    end
  end

  let(:mixlib_options) { Mixlib::Install::Options.new(options) }
  let(:package_router) { Mixlib::Install::Backend::PackageRouter.new(mixlib_options) }
  let(:artifact_info) { package_router.info }

  context "for chef/stable" do
    let(:channel) { :stable }
    let(:product_name) { "chef" }

    # 12.20.3 was released chronologically after 13.0.118. We want to make sure
    # it appears BEFORE 13.0.118 in the list of available versions to prove that
    # versions are sorted by semver rather than by release date.
    context "when there is a release of a previous major/minor version" do
      let(:idx_12_20_3) { package_router.available_versions.index("12.20.3") }
      let(:idx_13_0_118) { package_router.available_versions.index("13.0.118") }

      it "returns properly sorted list of available_versions" do
        expect(idx_12_20_3).to be < idx_13_0_118
      end
    end
  end

  context "for commercial API with license_id" do
    let(:channel) { :stable }
    let(:product_name) { "chef" }
    let(:product_version) { "18.0.0" }
    let(:license_id) { "test-license-key-123" }

    it "uses commercial API endpoint" do
      expect(package_router.endpoint).to eq Mixlib::Install::Dist::COMMERCIAL_API_ENDPOINT
    end

    it "detects commercial API usage" do
      expect(package_router.use_commercial_api?).to be true
    end

    context "with platform info" do
      let(:platform) { "ubuntu" }
      let(:platform_version) { "20.04" }
      let(:architecture) { "x86_64" }

      it "includes license_id in download URL" do
        # Mock the HTTP request to prevent actual API calls
        allow(package_router).to receive(:get).and_return({
          "results" => [{
            "name" => "chef_18.0.0-1_amd64.deb",
            "properties" => [
              { "key" => "omnibus.version", "value" => "18.0.0" },
              { "key" => "omnibus.platform", "value" => "ubuntu" },
              { "key" => "omnibus.platform_version", "value" => "20.04" },
              { "key" => "omnibus.architecture", "value" => "x86_64" },
              { "key" => "omnibus.project", "value" => "chef" },
              { "key" => "omnibus.license", "value" => "Apache-2.0" },
              { "key" => "omnibus.sha256", "value" => "abc123" },
              { "key" => "omnibus.md5", "value" => "def456" },
              { "key" => "omnibus.sha1", "value" => "ghi789" }
            ],
          },]
        })

        artifact = artifact_info
        expect(artifact.url).to include("license_id=#{license_id}")
      end
    end
  end

  context "for trial API with free- license_id" do
    let(:channel) { :stable }
    let(:product_name) { "chef" }
    let(:product_version) { "18.0.0" }
    let(:license_id) { "free-abc-def-123" }

    it "uses trial API endpoint" do
      expect(package_router.endpoint).to eq Mixlib::Install::Dist::TRIAL_API_ENDPOINT
    end

    it "detects trial API usage" do
      expect(package_router.use_trial_api?).to be true
    end

    it "does not detect commercial API usage" do
      expect(package_router.use_commercial_api?).to be false
    end

    it "detects licensed API usage" do
      expect(package_router.use_licensed_api?).to be true
    end

    context "with platform info" do
      let(:platform) { "ubuntu" }
      let(:platform_version) { "20.04" }
      let(:architecture) { "x86_64" }

      it "includes license_id in download URL" do
        # Mock the HTTP request to prevent actual API calls
        allow(package_router).to receive(:get).and_return({
          "results" => [{
            "name" => "chef_18.0.0-1_amd64.deb",
            "properties" => [
              { "key" => "omnibus.version", "value" => "18.0.0" },
              { "key" => "omnibus.platform", "value" => "ubuntu" },
              { "key" => "omnibus.platform_version", "value" => "20.04" },
              { "key" => "omnibus.architecture", "value" => "x86_64" },
              { "key" => "omnibus.project", "value" => "chef" },
              { "key" => "omnibus.license", "value" => "Apache-2.0" },
              { "key" => "omnibus.sha256", "value" => "abc123" },
              { "key" => "omnibus.md5", "value" => "def456" },
              { "key" => "omnibus.sha1", "value" => "ghi789" }
            ],
          },]
        })

        artifact = artifact_info
        expect(artifact.url).to include("license_id=#{license_id}")
      end
    end
  end

  context "for trial API with trial- license_id" do
    let(:channel) { :stable }
    let(:product_name) { "chef" }
    let(:product_version) { "18.0.0" }
    let(:license_id) { "trial-xyz-789-456" }

    it "uses trial API endpoint" do
      expect(package_router.endpoint).to eq Mixlib::Install::Dist::TRIAL_API_ENDPOINT
    end

    it "detects trial API usage" do
      expect(package_router.use_trial_api?).to be true
    end

    it "does not detect commercial API usage" do
      expect(package_router.use_commercial_api?).to be false
    end

    it "detects licensed API usage" do
      expect(package_router.use_licensed_api?).to be true
    end
  end

  context "without license_id" do
    let(:channel) { :stable }
    let(:product_name) { "chef" }
    let(:product_version) { "18.0.0" }

    it "uses standard endpoint" do
      expect(package_router.endpoint).to eq Mixlib::Install::Dist::PRODUCT_ENDPOINT
    end

    it "detects no commercial API usage" do
      expect(package_router.use_commercial_api?).to be false
    end

    it "detects no trial API usage" do
      expect(package_router.use_trial_api?).to be false
    end

    it "detects no licensed API usage" do
      expect(package_router.use_licensed_api?).to be false
    end
  end

  context "for chef/stable with specific version" do
    let(:channel) { :stable }
    let(:product_name) { "chef" }
    let(:product_version) { "12.12.15" }

    it "returns all artifacts" do
      expect(artifact_info.size).to be > 1
    end

    context "with platform info" do
      let(:platform) { "ubuntu" }
      let(:platform_version) { "14.04" }
      let(:architecture) { "x86_64" }

      shared_examples_for "artifact with core attributes" do
        it "is an ArtifactInfo instance" do
          expect(artifact_info).to be_a Mixlib::Install::ArtifactInfo
        end

        it "has the right platform" do
          expect(artifact_info.platform).to eq "ubuntu"
        end

        it "has the right platform version" do
          expect(artifact_info.platform_version).to eq "14.04"
        end

        it "has the right architecture" do
          expect(artifact_info.architecture).to eq "x86_64"
        end

        it "has the right sha256" do
          expect(artifact_info.sha256).to eq "d64a029bc5402e2c2e2e1ad479e8b49b3dc7599a9d50ea3cefe4149b070582be"
        end

        it "has the right license" do
          expect(artifact_info.license).to eq "Apache-2.0"
        end

        it "has the right product name" do
          expect(artifact_info.product_name).to eq "chef"
        end

        it "has the right product description" do
          expect(artifact_info.product_description).to eq "Chef Infra Client"
        end

        it "has the right url" do
          expect(artifact_info.url).to include "files/stable/chef/12.12.15/ubuntu/14.04/chef_12.12.15-1_amd64.deb"
        end
      end

      context "without metadata (default)" do
        it_behaves_like "artifact with core attributes"

        it "does not have license content" do
          expect(artifact_info.license_content).to be_nil
        end

        it "does not have software dependencies" do
          expect(artifact_info.software_dependencies).to be_nil
        end
      end

      context "with metadata" do
        let(:include_metadata) { true }

        it_behaves_like "artifact with core attributes"

        it "has the right license content" do
          expect(artifact_info.license_content).to include "http://www.apache.org/licenses/\n\nTERMS AND CONDITIONS FOR USE, REPRODUCTION, AND DISTRIBUTION"
        end

        it "has the right software dependencies" do
          expect(artifact_info.software_dependencies).to include "preparation"
        end
      end

      context "when an querying artifact" do
        it "does not return metadata.json" do
          expect(package_router.info).to be_a Mixlib::Install::ArtifactInfo
          expect(package_router.info.url).not_to include("metadata.json")
        end
      end
    end
  end

  context "for a product that does not exist in a specific channel" do
    let(:channel) { :unstable }
    let(:product_name) { "ha" }

    it "raises an exception" do
      expect { artifact_info }.to raise_error Mixlib::Install::Backend::ArtifactsNotFound
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
      expect { artifact_info }.to raise_error Mixlib::Install::Backend::ArtifactsNotFound
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
      expect { artifact_info }.to raise_error Mixlib::Install::Backend::ArtifactsNotFound
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

  context "for a version of windows that is not added to our matrix" do
    let(:channel) { :stable }
    let(:product_name) { "chefdk" }
    let(:product_version) { :latest }
    let(:platform) { "windows" }
    let(:platform_version) { "2016" }
    let(:architecture) { "x86_64" }

    it "can not find an artifact" do
      expect { artifact_info }.to raise_error Mixlib::Install::Backend::ArtifactsNotFound
    end

    context "when product_version compat mode is set" do
      let(:pv_compat) { true }

      it "finds an artifact" do
        expect(artifact_info).to be_a Mixlib::Install::ArtifactInfo
        expect(artifact_info.platform).to eq "windows"
        expect(artifact_info.platform_version).to eq "2012r2"
        expect(artifact_info.architecture).to eq "x86_64"
      end

      context "when a desktop version is set" do
        let(:platform_version) { "10" }

        it "finds an artifact" do
          expect(artifact_info).to be_a Mixlib::Install::ArtifactInfo
          expect(artifact_info.platform).to eq "windows"
          expect(artifact_info.platform_version).to eq "2012r2"
          expect(artifact_info.architecture).to eq "x86_64"
        end
      end

      context "when version ends with r2" do
        let(:platform_version) { "2012r2" }

        it "finds an artifact" do
          expect(artifact_info).to be_a Mixlib::Install::ArtifactInfo
          expect(artifact_info.platform).to eq "windows"
          expect(artifact_info.platform_version).to eq "2012r2"
          expect(artifact_info.architecture).to eq "x86_64"
        end
      end
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
      expect(package_router.info).to be_a Mixlib::Install::ArtifactInfo
      expect(package_router.info.url).to match "delivery"
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
      expect(package_router.info).to be_a Mixlib::Install::ArtifactInfo
      expect(package_router.info.url).to match "chef-compliance"
    end
  end

  context "for push jobs client" do
    let(:channel) { :stable }
    let(:product_name) { "push-jobs-client" }
    let(:platform) { "ubuntu" }
    let(:platform_version) { "12.04" }
    let(:architecture) { "x86_64" }

    context "for version 1.1.5" do
      let(:product_version) { "1.1.5" }

      it "uses omnibus project name" do
        expect(package_router.info).to be_a Mixlib::Install::ArtifactInfo
        expect(package_router.info.url).to match "opscode-push-jobs-client"
      end
    end

    context "for latest version" do
      let(:product_version) { :latest }

      it "uses omnibus project name" do
        expect(package_router.info).to be_a Mixlib::Install::ArtifactInfo
        expect(package_router.info.url).to match "push-jobs-client"
        expect(package_router.info.url).not_to match "opscode-push-jobs-client"
      end
    end
  end

  context "for manage" do
    let(:channel) { :stable }
    let(:product_name) { "manage" }
    let(:platform) { "ubuntu" }
    let(:platform_version) { "14.04" }
    let(:architecture) { "x86_64" }

    context "for version 1.21.0" do
      let(:product_version) { "1.21.0" }

      it "uses omnibus project name" do
        expect(package_router.info).to be_a Mixlib::Install::ArtifactInfo
        expect(package_router.info.url).to match "opscode-manage"
      end
    end

    context "for latest version" do
      let(:product_version) { :latest }

      it "uses omnibus project name" do
        expect(package_router.info).to be_a Mixlib::Install::ArtifactInfo
        expect(package_router.info.url).to match "chef-manage"
      end
    end
  end

  context "when querying automate" do
    let(:channel) { :unstable }
    let(:product_name) { "automate" }
    let(:product_version) { :latest }
    let(:platform) { "ubuntu" }
    let(:platform_version) { "14.04" }
    let(:architecture) { "x86_64" }

    it "uses the omnibus project name" do
      expect(package_router.info).to be_a Mixlib::Install::ArtifactInfo
      expect(package_router.info.url).to match "delivery"
    end
  end

  context "when querying compliance" do
    let(:channel) { :current }
    let(:product_name) { "compliance" }
    let(:product_version) { :latest }
    let(:platform) { "ubuntu" }
    let(:platform_version) { "14.04" }
    let(:architecture) { "x86_64" }

    it "uses the omnibus project name" do
      expect(package_router.info).to be_a Mixlib::Install::ArtifactInfo
      expect(package_router.info.url).to match "chef-compliance"
    end
  end

  context "when querying chef-server" do
    let(:channel) { :stable }
    let(:product_name) { "chef-server" }
    let(:product_version) { :latest }
    let(:platform) { "ubuntu" }
    let(:platform_version) { "14.04" }
    let(:architecture) { "x86_64" }

    it "uses the omnibus project name" do
      expect(package_router.info).to be_a Mixlib::Install::ArtifactInfo
      expect(package_router.info.url).to match "chef-server-core"
    end
  end

  context "user agents" do
    let(:channel) { :stable }
    let(:product_name) { "chef" }

    it "always includes default header" do
      expect(package_router.create_http_request("/").get_fields("user-agent")).to include "mixlib-install/#{Mixlib::Install::VERSION}"
    end

    context "with custom agents" do
      let(:user_agent_headers) { ["foo/bar", "someheader"] }

      it "sets custom header" do
        expect(package_router.create_http_request("/").get_fields("user-agent")).to include(/foo\/bar someheader/)
      end
    end
  end

  context "windows desktop artifacts" do
    let(:channel) { :stable }
    let(:windows_artifacts) do
      artifact_info.find_all { |a| a.platform == "windows" }
    end

    shared_examples_for "windows download urls and architectures" do
      it "returns server download url for associated desktop versions" do
        expected = product_name == "push-jobs-client" ? "2012r2" : "/windows/10/"
        expect(windows_artifacts.find { |a| a.platform_version == "10" }.url).to include expected
      end

      it "maps architecture to correct filename" do
        artifact_32 = windows_artifacts.find { |a| a.platform_version == "10" && a.architecture == "i386" }
        artifact_64 = windows_artifacts.find { |a| a.platform_version == "10" && a.architecture == "x86_64" }
        expect(artifact_32.url).to include "-x86" if artifact_32 # not all projects have 32-bit packages
        expect(artifact_64.url).to include expected_64_bit_msi
      end
    end

    context "chef artifacts" do
      let(:product_name) { "chef" }
      let(:expected_64_bit_msi) { "-x64" }

      it_behaves_like "windows download urls and architectures"
    end

    context "chefdk artifacts" do
      let(:product_name) { "chefdk" }
      let(:expected_64_bit_msi) { "-x64" }

      it_behaves_like "windows download urls and architectures"
    end

    context "push-jobs-client artifacts" do
      let(:product_name) { "push-jobs-client" }
      let(:expected_64_bit_msi) { "-x64" }

      it_behaves_like "windows download urls and architectures"
    end

    context "inspec artifacts" do
      let(:product_name) { "inspec" }
      let(:expected_64_bit_msi) { "-x64" }

      it_behaves_like "windows download urls and architectures"
    end

    context "chef-workstation artifacts" do
      let(:product_name) { "inspec" }
      let(:expected_64_bit_msi) { "-x64" }

      it_behaves_like "windows download urls and architectures"
    end
  end

  context "windows nano artifacts" do
    let(:channel) { :current }
    let(:product_name) { "angry-omnibus-toolchain" }
    let(:product_version) { "1.1.57" }

    context "without platform version" do
      it "does not return appx packages" do
        artifacts = artifact_info.find_all { |a| a.url.end_with?("appx") }
        expect(artifacts.size).to eq 0
      end

      it "returns msi packages" do
        artifacts = artifact_info.find_all { |a| a.url.end_with?("msi") }
        expect(artifacts.size).to be > 0
      end
    end

    context "with no found version" do
      let(:platform) { "windows" }
      let(:platform_version) { "2012r2" }
      let(:architecture) { "x86_64" }
      let(:product_version) { "99.99.99" }

      it "raises exception with 2012r2 platform version" do
        expect { artifact_info }.to raise_error(/platform version: #{platform_version}/)
      end
    end

    context "with platform version 2016nano" do
      let(:platform) { "windows" }
      let(:platform_version) { "2016nano" }
      let(:architecture) { "x86_64" }

      it "returns 2012r2 appx package" do
        expect(artifact_info.url).to include ".appx"
        expect(artifact_info.platform_version).to eq "2012r2"
      end

      context "with no found version" do
        let(:product_version) { "99.99.99" }

        it "raises exception with 2016nano platform version" do
          expect { artifact_info }.to raise_error(/platform version: #{platform_version}/)
        end
      end
    end
  end

  context "for partial product versions" do
    let(:product_name) { "chef" }
    let(:channel) { :stable }

    context "without platform info" do
      %w{
        13.2.
        13.2
        12.21.
        12.21
        11.18.
        11.18
      }.each do |version|
        context "for version #{version}" do
          let(:product_version) { version }
          let(:expected_version) do
            case version
            when "13.2.", "13.2"
              "13.2.20"
            when "12.21.", "12.21"
              "12.21.3"
            when "11.18.", "11.18"
              "11.18.12"
            else
              nil
            end
          end

          it "returns latest chef #{version} version" do
            versions = artifact_info.map { |a| a.version }.uniq
            expect(versions.size).to eq 1
            expect(versions.first).to eq expected_version
          end
        end
      end
    end

    context "with platform info" do
      let(:platform) { "ubuntu" }
      let(:platform_version) { "14.04" }
      let(:architecture) { "x86_64" }

      %w{
        11.18.
        12.1.
        12.14.
        12.21.
        13.2.
      }.each do |version|
        context "for version #{version}" do
          let(:product_version) { version }
          let(:expected_version) do
            case version
            when "13", "13.2."
              "13.2.20"
            when "12", "12.21."
              "12.21.3"
            when "12.1", "12.1."
              "12.1.2"
            when "12.14", "12.14."
              "12.14.89"
            when "11", "11.18.", "11.18"
              "11.18.12"
            else
              nil
            end
          end

          it "returns latest chef #{version} version" do
            expect(artifact_info.version).to eq expected_version
          end
        end
      end
    end
  end

  context "artifact missing metadata" do
    let(:channel) { :stable }
    let(:product_name) { "supermarket" }
    let(:product_version) { "2.5.2" }
    let(:platform) { "ubuntu" }
    let(:platform_version) { "14.04" }
    let(:architecture) { "x86_64" }
    let(:include_metadata) { true }

    it "does not have license content" do
      expect(artifact_info.license_content).to be_nil
    end

    it "does not have software dependencies" do
      expect(artifact_info.software_dependencies).to be_nil
    end
  end
end
