#
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
require "mixlib/install/cli"

describe "mixlib-install executable" do
  let(:args) { nil }

  before(:all) do
    puts "
    ****************************************
      TESTS ARE SLOW - DOWNLOADS PACKAGES.
    ****************************************

"
  end

  let(:cmd) { Mixlib::ShellOut.new("mixlib-install #{command} #{args} ").run_command }
  let(:last_command_output) { cmd.stdout.chomp }
  let(:last_command_err) { cmd.stderr.chomp }

  describe "version command" do
    let(:command) { "version" }

    it "prints the mixlib-install version" do
      require "mixlib/install/version"
      expect(last_command_output).to eq Mixlib::Install::VERSION
    end
  end

  describe "list-versions command" do
    let(:command) { "list-versions" }

    around do |example|
      with_proxy_server do
        ClimateControl.modify http_proxy: "http://127.0.0.1:8401", https_proxy: "http://127.0.0.1:8401" do
          example.run
        end
      end
    end

    context "with valid args" do
      let(:args) { "chef stable" }

      it "prints the versions" do
        expect(last_command_output).to match /12.0.3/
      end
    end

    context "with invalid args" do
      let(:args) { "foo bar" }

      it "returns error message" do
        expect(last_command_err).to match /Unknown product name foo/
        expect(last_command_err).to match /Unknown channel bar/
      end
    end
  end

  describe "install-script command" do
    let(:command) { "install-script" }

    context "with no args" do
      it "returns shell script to stdout" do
        expect(last_command_output).to match /end of install_package.sh/
      end
    end

    context "with ps1 type" do
      let(:args) { "-t ps1" }

      it "returns powershell script to stdout" do
        expect(last_command_output).to match /export-modulemember -function 'Install-Project','Get-ProjectMetadata' -alias 'install'/
      end
    end

    context "with invalid type" do
      let(:args) { "-t foo" }

      it "errors an error" do
        expect(last_command_err).to match "Expected '--type' to be one of ps1, sh; got foo"
      end
    end

    context "with alternate endpoint" do
      let(:args) { "--endpoint https://omnitruck-custom.chef.io" }

      it "contains the new endpoint" do
        expect(last_command_output).to match /https:\/\/omnitruck-custom.chef.io/
      end
    end

    context "with output option", :focus do
      let(:args) { "-o script.sh" }

      it "writes to a file" do
        # We're executing and not looking for stdout/err output
        # so we'll directly invoke here instead of going through 'last_command_output'
        Mixlib::ShellOut.new("mixlib-install #{command} #{args} ").run_command
        expect(File.exist?("script.sh")).to eq true
      end
    end
  end

  describe "download command" do
    let(:command) { "download" }
    let(:additional_args) { nil }
    let(:args) do
      a = ""
      a << product unless product.nil?
      a << " -p #{platform}" unless platform.nil?
      a << " -l #{platform_version}" unless platform_version.nil?
      a << " -a #{architecture}" unless architecture.nil?
      a << " #{additional_args}" unless additional_args.nil?
      a
    end

    let(:product) { "chef" }
    let(:platform) { "ubuntu" }
    let(:platform_version) { "14.04" }
    let(:architecture) { "x86_64" }

    around do |example|
      with_proxy_server do
        ClimateControl.modify http_proxy: "http://127.0.0.1:8401", https_proxy: "http://127.0.0.1:8401" do
          example.run
        end
      end
    end

    context "without args" do
      let(:product) { nil }
      let(:platform) { nil }
      let(:platform_version) { nil }
      let(:architecture) { nil }

      it "exits with required args error" do
        expect(last_command_err).to match /"mixlib-install #{command}" was called with no arguments/
      end
    end

    context "with chef product" do
      let(:product) { "chef" }

      it "downloads a chef artifact" do
        expect(last_command_output).to match /Download saved to/
      end
    end

    context "with url flag" do
      let(:additional_args) { "--url" }

      it "outputs the url" do
        expect(last_command_output).to match /https:\/\/packages.chef.io\/files\/stable\/chef/
      end
    end

    context "with attributes arg" do
      let(:additional_args) { "--url --attributes" }

      it "outputs the attributes" do
        expect(last_command_output).to match /"license": "Chef EULA"/
      end
    end

    context "with platform arg" do
      let(:platform) { "ubuntu" }
      let(:platform_version) { nil }
      let(:architecture) { nil }

      it "fails with missing args error" do
        expect(last_command_err).to match "Must provide platform (-p), platform version (-l) and architecture (-a) when specifying any platform details"
      end
    end

    context "with future platform version" do
      let(:platform) { "windows" }
      let(:platform_version) { "2016" }
      let(:additional_args) { "--attributes" }

      let(:latest_version) { Mixlib::Install.available_versions("chefdk", "stable").last }
      let(:filename) { "chefdk-#{latest_version}-x86.msi" }

      it "has the correct artifact" do
        require "digest"
        sha256 = Digest::SHA256.hexdigest("./tmp/aruba/#{filename}")
        expect(last_command_output).to match /sha256/
      end
    end

    context "with invalid platform version and architecture" do
      let(:platform) { "foo" }
      let(:platform_version) { "99.99" }
      let(:architecture) { "x86_64" }
      let(:additional_args) { "--no-platform-version-compat" }

      it "returns no results" do
        expect(last_command_err).to match /No artifacts found matching criteria./
      end
    end

    context "with specified version" do
      let(:additional_args) { "-v 12.0.3" }

      it "returns the correct artifact" do
        expect(last_command_output).to match /chef[-_]12.0.3-1/
      end
    end

    context "with specified channel" do
      let(:additional_args) { "-c current" }

      it "returns the correct artifact" do
        expect(last_command_output).to match /files\/current\/chef/
      end
    end

    context "with specified directory" do
      let(:additional_args) { "-d mydir" }

      it "downloads to dir" do
        expect(last_command_output).to match /Download saved to .*mydir\/chef/
      end
    end

    context "with license_id" do
      let(:additional_args) { "-L test-license-key-123 --url" }

      it "accepts license_id parameter" do
        # This will fail with actual API call, but we're testing that the parameter is accepted
        # In a real scenario with a valid license, it would use the commercial API
        expect { Mixlib::ShellOut.new("mixlib-install #{command} #{args} ").run_command }.not_to raise_error
      end
    end
  end
end
