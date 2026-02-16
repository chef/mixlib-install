#
# Author:: Thom May (<thom@chef.io>)
# Author:: Patrick Wright (<patrick@chef.io>)
# Copyright:: Copyright (c) 2015-2025 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
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
require "mixlib/install/script_generator"

describe Mixlib::Install::ScriptGenerator do
  describe "#initialize" do
    it "sets a version" do
      install = described_class.new("1.2.1")
      expect(install.version).to eq("1.2.1")
    end

    it "has a default version" do
      install = described_class.new(nil)
      expect(install.version).to eq("latest")
    end

    it "sets that powershell is used" do
      install = described_class.new("1.2.1", true)
      expect(install.powershell).to be true
    end

    describe "manages the install root" do
      it "on windows" do
        install = described_class.new("1.2.1", true)
        expect(install.root).to eq("$env:systemdrive\\opscode\\chef")
      end

      it "on unix" do
        install = described_class.new("1.2.1", false)
        expect(install.root).to eq("/opt/chef")
      end

      it "is settable" do
        install = described_class.new("1.2.1", false, root: "/opt/test")
        expect(install.root).to eq("/opt/test")
      end
    end

    describe "parses the options hash" do
      it "enables sudo" do
        opts = { sudo_command: "sudo -i -E" }
        install = described_class.new("1.2.1", false, opts)
        expect(install.use_sudo).to be true
        expect(install.sudo_command).to eq("sudo -i -E")
      end

      it "sets the metadata endpoint" do
        opts = { endpoint: "chef-server" }
        install = described_class.new("1.2.1", false, opts)
        expect(install.endpoint).to eq("metadata-chef-server")
      end

      it "sets the base URL" do
        opts = { omnibus_url: "http://example.com/install.sh" }
        install = described_class.new("1.2.1", false, opts)
        expect(install.omnibus_url).to eq("http://example.com/install.sh")
      end

      it "raises ArgumentError on invalid options" do
        opts = { invalid_arg: true }
        expect { described_class.new("1.2.1", false, opts) }.to raise_error(ArgumentError)
      end

      it "sets the license_id" do
        opts = { license_id: "test-license-123" }
        install = described_class.new("1.2.1", false, opts)
        expect(install.license_id).to eq("test-license-123")
      end
    end
  end

  describe "#install" do
    describe "on windows" do
      let(:installer) { described_class.new("1.2.1", true, omnibus_url: "http://f/install.sh") }
      let(:target_url) { "http://f/metadata?p=windows&m=$platform_architecture&pv=$platform_version&v=1.2.1" }
      let(:powershell_prefix) { "powershell helpers" }

      it "generates config vars" do
        expect(installer).to receive(:install_command_vars_for_powershell)
        installer.install_command
      end

      it "creates the target url" do
        expect(installer).to receive(:windows_metadata_url).and_call_original
        installer.install_command
      end

      it "builds the command string" do
        allow(installer).to receive(:install_command_vars_for_powershell).and_return("a test string")
        expect(installer).to receive(:shell_code_from_file).with("a test string")
        installer.install_command
      end

      it "creates the proper shell vars" do
        expect(installer.install_command).to match(%r{\$chef_metadata_url = "#{Regexp.escape(target_url)}"})
      end

      it "sets the default download_directory" do
        expect(installer.install_command).to match(%r{\$download_directory = "\$env:TEMP"})
      end

      it "includes powershell helpers for platform version and arch detection" do
        expect(installer).to receive(:powershell_prefix).and_return(powershell_prefix)
        expect(installer.install_command).to include(powershell_prefix)
      end

      describe "customizing -download_directory through install_flags" do
        let(:download_directory) { "C:\\bubulubu" }
        let(:install_flags) { "-download_directory #{download_directory}" }

        before { installer.install_flags = install_flags }

        it "sets the custom download_directory variable" do
          expect(installer.install_command).to match(%r{\$download_directory = "#{Regexp.escape(download_directory)}"})
        end
      end

      describe "for a nightly" do
        let(:installer) { described_class.new("1.2.1", true, omnibus_url: "http://f/install.sh", nightlies: true) }
        let(:target_url) { "http://f/metadata?p=windows&m=$platform_architecture&pv=$platform_version&v=1.2.1&nightlies=true" }

        it "creates the proper shell vars" do
          expect(installer.install_command).to match(%r{\$chef_metadata_url = "#{Regexp.escape(target_url)}"})
        end
      end

      describe "with an MSI url" do
        let(:installer) { described_class.new("1.2.1", true, install_msi_url: "http://f/chef.msi") }

        it "does not create the target url" do
          expect(installer).to_not receive(:windows_metadata_url)
          installer.install_command
        end

        it "creates the proper shell vars" do
          expect(installer.install_command).to match(%r{chef_msi_url.*http://f/chef.msi})
        end
      end

      describe "with a license_id" do
        let(:installer) { described_class.new("1.2.1", true, omnibus_url: "http://f/install.sh", license_id: "test-license-456") }

        it "stores the license_id" do
          expect(installer.license_id).to eq("test-license-456")
        end

        it "includes license_id as a variable in powershell script" do
          expect(installer.install_command).to match(/\$license_id = "test-license-456"/)
        end
      end

      describe "with chef product" do
        let(:installer) { described_class.new("latest", true, omnibus_url: "http://f/install.sh", project: "chef", license_id: "test-chef-123") }

        it "uses stable/chef/metadata endpoint" do
          metadata_url = installer.send(:windows_metadata_url)
          expect(metadata_url).to include("stable/chef/metadata")
        end

        it "includes pv parameter for chef" do
          metadata_url = installer.send(:windows_metadata_url)
          expect(metadata_url).to include("pv=$platform_version")
          expect(metadata_url).not_to include("pm=")
        end
      end
    end

    describe "on unix" do
      let(:installer) { described_class.new("1.2.1", false, omnibus_url: "http://f/", nightlies: true) }

      it "generates config vars" do
        expect(installer).to receive(:install_command_vars_for_bourne)
        installer.install_command
      end

      it "passes a flag to install a nightly" do
        expect(installer.install_command).to include('install_flags="-v 1.2.1 -n"')
      end

      it "will install a nightly, if necessary" do
        installer = described_class.new("12.5.0-current.0+20150721082808.git.14.c91b337-1", false)
        out = installer.install_command
        expect(out).to include(%{install_flags="-v 12.5.0-current.0%2B20150721082808.git.14.c91b337-1"})
        expect(out).to include(%{version="12.5.0-current.0+20150721082808.git.14.c91b337-1"})
      end

      describe "with a license_id" do
        let(:installer) { described_class.new("1.2.1", false, omnibus_url: "https://omnitruck.chef.io/install.sh", license_id: "test-license-789") }

        it "stores the license_id" do
          expect(installer.license_id).to eq("test-license-789")
        end

        it "includes license_id in install_flags for bourne script" do
          out = installer.install_command
          expect(out).to include('install_flags="-v 1.2.1 -l test-license-789"')
        end

        it "uses commercial URL for non-trial licenses" do
          out = installer.install_command
          expect(out).to include('chef_omnibus_url="https://chefdownload-commercial.chef.io/install.sh?license_id=test-license-789"')
        end
      end

      describe "with a trial license" do
        let(:installer) { described_class.new("latest", false, omnibus_url: "https://omnitruck.chef.io/install.sh", license_id: "trial-abc123") }

        it "uses trial URL for trial licenses" do
          out = installer.install_command
          expect(out).to include('chef_omnibus_url="https://chefdownload-trial.chef.io/install.sh?license_id=trial-abc123"')
        end

        it "uses trial URL for free licenses" do
          installer.license_id = "free-xyz789"
          out = installer.install_command
          expect(out).to include('chef_omnibus_url="https://chefdownload-trial.chef.io/install.sh?license_id=free-xyz789"')
        end
      end

      describe "with custom omnibus_url and license" do
        let(:installer) { described_class.new("latest", false, omnibus_url: "https://custom.example.com/install.sh", license_id: "test-123") }

        it "preserves custom URLs" do
          out = installer.install_command
          expect(out).to include('chef_omnibus_url="https://custom.example.com/install.sh"')
        end
      end

      describe "sudo command handling" do
        it "uses sudo by default" do
          installer = described_class.new("1.2.1", false)
          out = installer.install_command
          expect(out).to include('sudo_sh="sudo -E sh"')
        end

        it "disables sudo when sudo_command is nil" do
          installer = described_class.new("1.2.1", false, sudo_command: nil)
          expect(installer.use_sudo).to be false
          out = installer.install_command
          expect(out).to include('sudo_sh="sh"')
        end

        it "uses custom sudo command" do
          installer = described_class.new("1.2.1", false, sudo_command: "doas")
          out = installer.install_command
          expect(out).to include('sudo_sh="doas sh"')
        end
      end
    end
  end

  describe "private methods" do
    describe "#omnibus_url_for_license" do
      let(:installer) { described_class.new("latest", false, omnibus_url: "https://omnitruck.chef.io/install.sh") }

      context "without license_id" do
        it "returns original omnibus_url" do
          expect(installer.send(:omnibus_url_for_license)).to eq("https://omnitruck.chef.io/install.sh")
        end
      end

      context "with commercial license_id" do
        before { installer.license_id = "commercial-abc123" }

        it "returns commercial URL with license_id" do
          url = installer.send(:omnibus_url_for_license)
          expect(url).to eq("https://chefdownload-commercial.chef.io/install.sh?license_id=commercial-abc123")
        end
      end

      context "with trial license_id" do
        before { installer.license_id = "trial-xyz789" }

        it "returns trial URL with license_id" do
          url = installer.send(:omnibus_url_for_license)
          expect(url).to eq("https://chefdownload-trial.chef.io/install.sh?license_id=trial-xyz789")
        end
      end

      context "with free license_id" do
        before { installer.license_id = "free-test123" }

        it "returns trial URL with license_id" do
          url = installer.send(:omnibus_url_for_license)
          expect(url).to eq("https://chefdownload-trial.chef.io/install.sh?license_id=free-test123")
        end
      end

      context "with non-install.sh URL" do
        before do
          installer.omnibus_url = "https://example.com/custom_path"
          installer.license_id = "test-123"
        end

        it "returns original URL unchanged" do
          expect(installer.send(:omnibus_url_for_license)).to eq("https://example.com/custom_path")
        end
      end
    end

    describe "#windows_metadata_url" do
      context "without license (omnitruck path)" do
        let(:installer) { described_class.new("16.0.0", true, omnibus_url: "https://omnitruck.chef.io/install.sh") }

        it "constructs omnitruck metadata URL" do
          url = installer.send(:windows_metadata_url)
          expect(url).to eq("https://omnitruck.chef.io/metadata?p=windows&m=$platform_architecture&pv=$platform_version&v=16.0.0")
        end

        it "includes nightlies parameter when set" do
          installer.nightlies = true
          url = installer.send(:windows_metadata_url)
          expect(url).to include("&nightlies=true")
        end

        it "includes prerelease parameter when set" do
          installer.prerelease = true
          url = installer.send(:windows_metadata_url)
          expect(url).to include("&prerelease=true")
        end

        it "omits version for latest" do
          installer.version = "latest"
          url = installer.send(:windows_metadata_url)
          expect(url).not_to include("&v=")
        end
      end
    end
  end
end
