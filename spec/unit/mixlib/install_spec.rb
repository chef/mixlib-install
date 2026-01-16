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
require "mixlib/install"

context "Mixlib::Install" do
  let(:installer) do
    Mixlib::Install.new(
      product_name: product_name,
      channel: channel,
      product_version: product_version,
      platform: platform,
      platform_version: platform_version,
      architecture: architecture
    )
  end

  let(:channel) { :stable }
  let(:product_version) { :latest }
  let(:platform) { nil }
  let(:platform_version) { nil }
  let(:architecture) { nil }

  context "querying current version" do
    let(:version_manifest_file) { "/opt/#{product_name}/version-manifest.json" }

    context "when products are installed" do
      before do
        expect(File).to receive(:exist?).with(version_manifest_file).and_return(true)
        expect(File).to receive(:read).with(version_manifest_file).and_wrap_original do |m, path|
          m.call(File.join(VERSION_MANIFEST_DIR, path))
        end
      end

      context "with product name chef" do
        let(:product_name) { "chef" }

        it "should report version correctly" do
          expect(installer.current_version).to eq("12.4.3")
        end
      end

      context "with product name chef" do
        let(:product_name) { "chefdk" }

        it "should report version correctly" do
          expect(installer.current_version).to eq("0.7.0")
        end
      end
    end

    context "when product is not installed" do
      let(:product_name) { "chef" }

      before do
        expect(File).to receive(:exist?).with(version_manifest_file).and_return(false)
      end

      it "should report version as nil" do
        expect(installer.current_version).to eq(nil)
      end
    end
  end

  context "checking for upgrades", :vcr do
    before do
      allow(installer).to receive(:current_version).and_return(current_version)
    end

    context "with nil as current_version" do
      let(:product_name) { "chefdk" }
      let(:channel) { :stable }
      let(:product_version) { :latest }
      let(:current_version) { nil }

      it "should report upgrade available" do
        expect(installer.upgrade_available?).to eq(true)
      end
    end

    context "with :latest, upgrade exists, :stable channel" do
      let(:product_name) { "chefdk" }
      let(:channel) { :stable }
      let(:product_version) { :latest }
      let(:current_version) { "0.4.0" }

      it "should report upgrade available" do
        expect(installer.upgrade_available?).to eq(true)
      end
    end

    context "with specific version lower than current, :stable channel" do
      let(:product_name) { "chefdk" }
      let(:channel) { :stable }
      let(:product_version) { "0.3.0" }
      let(:current_version) { "0.4.0" }

      it "should report upgrade available" do
        expect(installer.upgrade_available?).to eq(false)
      end
    end

    context "with specific version higher than current, :stable channel" do
      let(:product_name) { "chefdk" }
      let(:channel) { :stable }
      let(:product_version) { "0.7.0" }
      let(:current_version) { "0.4.0" }

      it "should report upgrade available" do
        expect(installer.upgrade_available?).to eq(true)
      end
    end

    context "with specific platform options" do
      let(:product_name) { "chefdk" }
      let(:platform) { "ubuntu" }
      let(:platform_version) { "14.04" }
      let(:architecture) { "x86_64" }
      let(:current_version) { nil }

      it "should report upgrade available" do
        expect(installer.upgrade_available?).to eq(true)
      end
    end
  end

  context "install_sh" do
    let(:base_url) { nil }
    let(:license_id) { nil }

    let(:install_sh) do
      options = {}.tap do |opt|
        opt[:base_url] = base_url if base_url
        opt[:license_id] = license_id if license_id
      end
      Mixlib::Install.install_sh(options)
    end

    it "should render a script with cli parameters" do
      expect(install_sh).to include("while getopts pnv:c:f:P:d:s:l:a:L: opt")
    end

    context "with custom base_url" do
      let(:base_url) { "https://my.omnitruck.com/" }

      it "should render with the given base_url" do
        expect(install_sh).to include(base_url)
      end
    end

    it "should render with default base_url if one is not given" do
      expect(install_sh).to include("https://omnitruck.chef.io")
    end

    context "with license_id" do
      let(:license_id) { "test-license-123" }

      it "should pre-set license_id variable" do
        expect(install_sh).to include("# License ID provided via context")
        expect(install_sh).to include("license_id='test-license-123'")
      end
    end

    context "without license_id" do
      it "should not include license_id pre-set" do
        expect(install_sh).not_to include("# License ID provided via context")
        expect(install_sh).not_to include("license_id='")
      end
    end
  end

  context "install_ps1" do
    let(:base_url) { nil }
    let(:license_id) { nil }

    let(:install_ps1) do
      options = {}.tap do |opt|
        opt[:base_url] = base_url if base_url
        opt[:license_id] = license_id if license_id
      end
      Mixlib::Install.install_ps1(options)
    end

    it "should render a script with cli & backcompat parameters" do
      expect(install_ps1).not_to include("install -project")
      expect(install_ps1).to include("Get-ProjectMetadata -project $project -channel $channel -version $version -prerelease:$prerelease -nightlies:$nightlies")
    end

    context "with custom base_url" do
      let(:base_url) { "https://my.omnitruck.com/" }

      it "should render with the given base_url" do
        expect(install_ps1).to include(base_url)
      end
    end

    it "should render with default base_url if one is not given" do
      expect(install_ps1).to include("https://omnitruck.chef.io")
    end

    context "with license_id" do
      let(:license_id) { "trial-license-456" }

      it "should include license_id in install command" do
        expect(install_ps1).to include("# License ID provided via context - adding to install command")
        expect(install_ps1).to include("install -license_id 'trial-license-456'")
      end
    end

    context "without license_id" do
      it "should not include license_id in install command" do
        expect(install_ps1).not_to include("# License ID provided via context - adding to install command")
        expect(install_ps1).not_to include("install -license_id")
      end
    end
  end

  context "self.detect_platform" do
    let(:product_name) { "chef" }
    let(:platform_info) { Mixlib::Install.detect_platform }

    it "should return platform info" do
      expect(platform_info.size).to eq 3
      expect(installer.options.platform).to be_nil
      expect(installer.options.platform_version).to be_nil
      expect(installer.options.architecture).to be_nil
    end
  end

  context "detect_platform" do
    let(:product_name) { "chef" }

    it "should set options" do
      installer.detect_platform
      expect(installer.options.platform).not_to be_nil
      expect(installer.options.platform_version).not_to be_nil
      expect(installer.options.architecture).not_to be_nil
    end
  end

  context "detect_platform_sh" do
    let(:script) { Mixlib::Install.detect_platform_sh }

    it "should return platform_detection.sh" do
      expect(script).to include('echo "$platform $platform_version $machine"')
    end

    it "should return platform_detection.sh using grep without -q" do
      expect(script).not_to include("grep.*-q")
    end
  end

  context "detect_platform_ps1" do
    let(:script) { Mixlib::Install.detect_platform_ps1 }

    it "should return platform_detection.ps1" do
      expect(script).to include('Write-Host "windows $platform_version $architecture"')
    end
  end

  context "available_versions", :vcr do
    let(:product_name) { "chef" }
    let(:channel) { :stable }

    shared_examples_for "the correct available_versions" do
      it "is an Array" do
        expect(versions).to be_a Array
      end

      it "has expected version" do
        expect(versions).to include "12.0.3"
      end
    end

    context "when called as instance method" do
      let(:versions) { installer.available_versions }

      it_behaves_like "the correct available_versions"
    end

    context "when called static" do
      let(:versions) { Mixlib::Install.available_versions(product_name, channel.to_s) }

      it_behaves_like "the correct available_versions"
    end
  end

  describe "#download_artifact" do
    let(:product_name) { "chefdk" }

    context "when platform options are not set" do
      it "will raise an error" do
        expect { installer.download_artifact }.to raise_error /Must provide platform options to download a specific artifact/
      end
    end
  end
end
