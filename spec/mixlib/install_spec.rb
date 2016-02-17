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
require "mixlib/install"

context "Mixlib::Install" do
  let(:installer) do
    Mixlib::Install.new(
      product_name: product_name,
      channel: channel,
      product_version: product_version,
    )
  end

  let(:channel) { :stable }
  let(:product_version) { :latest }

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

  context "checking for upgrades" do
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
  end

  context "install_sh" do
    let(:base_url) { nil }

    let(:install_sh) do
      options = {}.tap do |opt|
        opt[:base_url] = base_url if base_url
      end
      Mixlib::Install.install_sh(options)
    end

    it "should render a script with cli parameters" do
      expect(install_sh).to include("while getopts pnv:c:f:P:d: opt")
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
  end

  context "install_ps1" do
    let(:base_url) { nil }

    let(:install_ps1) do
      options = {}.tap do |opt|
        opt[:base_url] = base_url if base_url
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
  end

end
