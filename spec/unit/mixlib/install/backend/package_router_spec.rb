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
    end
  end

  let(:mixlib_options) { Mixlib::Install::Options.new(options) }
  let(:package_router) { Mixlib::Install::Backend::PackageRouter.new(mixlib_options) }
  let(:artifact_info) { package_router.info }

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

        it "has the right platfom version" do
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
          expect(artifact_info.product_description).to eq "Chef Client"
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

  describe "#http" do
    let(:channel) { :stable }
    let(:product_name) { "chef" }

    context "default user agents" do
      it "always includes default header" do
        expect(package_router.http.default_options.headers["User-Agent"]).to match /mixlib-install\/#{Mixlib::Install::VERSION}/
      end
    end

    context "with custom agents" do
      let(:user_agent_headers) { ["foo/bar", "someheader"] }

      it "sets custom header" do
        expect(package_router.http.default_options.headers["User-Agent"]).to match /foo\/bar someheader/
      end
    end
  end

  context "windows desktop artifacts" do
    let(:channel) { :stable }
    let(:windows_artifacts) do
      artifact_info.find_all { |a| a.platform == "windows" }
    end

    shared_examples_for "windows desktop download urls and expected architectures" do
      it "returns server download url for associated desktop versions" do
        expect(windows_artifacts.find { |a| a.platform_version == "7" }.url).to include "2008r2"
        expect(windows_artifacts.find { |a| a.platform_version == "8" }.url).to include "2012"
        expect(windows_artifacts.find { |a| a.platform_version == "8.1" }.url).to include "2012r2"
        expect(windows_artifacts.find { |a| a.platform_version == "10" }.url).to include "2012r2"
      end

      it "maps architecture to correct filename" do
        expect(windows_artifacts.find { |a| a.platform_version == "7" && a.architecture == "i386" }.url).to include "-x86"
        expect(windows_artifacts.find { |a| a.platform_version == "7" && a.architecture == "x86_64" }.url).to include expected_64_bit_msi
      end
    end

    context "chef windows artifacts" do
      let(:product_name) { "chef" }
      let(:expected_64_bit_msi) { "-x64" }

      it_behaves_like "windows desktop download urls and expected architectures"
    end

    context "chefdk windows artifacts" do
      let(:product_name) { "chefdk" }
      let(:expected_64_bit_msi) { "-x86" }

      it_behaves_like "windows desktop download urls and expected architectures"
    end

    context "push-jobs-client windows artifacts" do
      let(:product_name) { "push-jobs-client" }
      let(:expected_64_bit_msi) { "-x86" }

      it_behaves_like "windows desktop download urls and expected architectures"
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
        12
        11.18.
      }.each do |version|
        context "for version #{version}" do
          let(:product_version) { version }
          let(:expected_version) do
            case version
            when "12"
              "12.19.36"
            when "11.18."
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
        12
        12.
        11
        12.1
        12.14
        12.14.
      }.each do |version|
        context "for version #{version}" do
          let(:product_version) { version }
          let(:expected_version) do
            case version
            when "12", "12."
              "12.19.36"
            when "12.1", "12.1."
              "12.1.2"
            when "12.14", "12.14."
              "12.14.89"
            when "11", "11."
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

  describe "#available_artifacts" do
    let(:channel) { :stable }
    let(:product_name) { "chef" }

    context "latest version" do
      let(:product_version) { :latest }

      it "returns available_artifacts" do
        expect(package_router.available_artifacts.first.version).to eq "13.0.118"
      end
    end

    context "partial version" do
      let(:product_version) { "12.12" }

      it "returns available_artifacts" do
        expect(package_router.available_artifacts.first.version).to eq "12.12.15"
      end
    end

    context "specific version" do
      let(:product_version) { "12.12.15" }

      it "returns available_artifacts" do
        expect(package_router.available_artifacts.first.version).to eq "12.12.15"
      end
    end
  end

  describe "#available_versions" do
    let(:channel) { :stable }
    let(:product_name) { "chef" }

    it "returns list of available versions" do
      expect(package_router.available_versions).to include "12.12.15"
    end
  end

  describe "#versions" do
    let(:channel) { :stable }
    let(:product_name) { "chef" }

    it "returns list of available versions" do
      expect(package_router.versions.first["properties"][0]["value"]).to eq "12.0.3"
    end
  end

  describe "#latest_version" do
    let(:channel) { :stable }
    let(:product_name) { "chef" }

    context "partial version" do
      let(:product_version) { "12.12" }

      it "returns list of latest versions for partial version" do
        expect(package_router.latest_version.first.version).to eq "12.12.15"
      end
    end

    context "partial version with ." do
      let(:product_version) { "12.12." }

      it "returns list of latest versions for partial version" do
        expect(package_router.latest_version.first.version).to eq "12.12.15"
      end
    end

    context "latest version" do
      let(:product_version) { :latest }

      it "returns list of latest versions for partial version" do
        expect(package_router.latest_version.first.version).to eq "13.0.118"
      end
    end
  end

  describe "#extract_version_from_response" do
    let(:channel) { :stable }
    let(:product_name) { "chef" }
    let(:product_version) { "12.12.15" }

    it "returns version" do
      response = {
        "properties" => [{ "key" => "omnibus.version", "value" => product_version }],
      }
      expect(package_router.extract_version_from_response(response)).to eq product_version
    end
  end

  describe "#artifacts_for_version" do
    let(:channel) { :stable }
    let(:product_name) { "chef" }

    context "with valid version" do
      let(:product_version) { "12.12.15" }

      it "returns list of artifacts" do
        expect(package_router.artifacts_for_version(product_version).first).to be_a Mixlib::Install::ArtifactInfo
      end
    end

    context "version not found" do
      let(:product_version) { "99.99.99" }

      it "returns empty list" do
        expect(package_router.artifacts_for_version(product_version)).to eq []
      end
    end
  end

  describe "#create_artifact" do
    let(:channel) { :stable }
    let(:product_name) { "chef" }
    let(:artifact_map) do
      {
        "filename" => "chef-12.17.16-1.sparc.solaris",
        "omnibus.license" => "Apache-2.0",
        "sha1" => "5a780a1aa1bfce7f85bdca96b0954976d821a2b4",
        "delivery.change" => nil,
        "omnibus.sha256" => "36f98876e63c2f09d7d56a194771efb9b3a27515daa97242fb6922e459c895b4",
        "delivery.sha" => nil,
        "sha256" => "36f98876e63c2f09d7d56a194771efb9b3a27515daa97242fb6922e459c895b4",
        "md5" => "a7cbba657b951554572b31a1b63b5331",
        "build.number" => "12.17.16",
        "omnibus.platform_version" => "10",
        "omnibus.md5" => "a7cbba657b951554572b31a1b63b5331",
        "omnibus.sha512" => "e8eac47e768170d937879f9051413785beee8918bcee65ea4c109a2d7d9b46c84b5f6b3e8d81aa7f17cbd8f05dae69db6ce45d1f7b58600b93614c178a56158f",
        "omnibus.version" => "12.17.16",
        "omnibus.project" => "chef",
        "omnibus.iteration" => "1",
        "build.name" => "chef",
        "omnibus.architecture" => "sparc",
        "omnibus.sha1" => "5a780a1aa1bfce7f85bdca96b0954976d821a2b4",
        "omnibus.platform" => "solaris",
        "sha512" => "e8eac47e768170d937879f9051413785beee8918bcee65ea4c109a2d7d9b46c84b5f6b3e8d81aa7f17cbd8f05dae69db6ce45d1f7b58600b93614c178a56158f",
      }
    end

    let(:artifact) { package_router.create_artifact(artifact_map) }

    it "normalizes platform" do
      expect(artifact.platform).to eq "solaris2"
    end

    it "normalizes platform version" do
      expect(artifact.platform_version).to eq "5.10"
    end

    it "use compat download url" do
      expect(artifact.url).to match /^http:/
    end
  end

  describe "#use_compat_download_url_endpoint?" do
    let(:channel) { :stable }
    let(:product_name) { "chef" }

    context "compat platforms" do
      ["freebsd-9", "el-5", "solaris2-5.9", "solaris2-5.10"].each do |plat|
        it "uses compat URL" do
          s = plat.split("-")
          expect(package_router.use_compat_download_url_endpoint?(s.first, s.last)).to be true
        end
      end
    end

    context "non-compat platform" do
      it "uses normal URL" do
        expect(package_router.use_compat_download_url_endpoint?("ubuntu", "14.04")).to be false
      end
    end
  end
end
