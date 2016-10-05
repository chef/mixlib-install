#
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

require_relative "./spec_helper"
require "mixlib/install/cli"

describe "mixlib-install executable", :type => :aruba do
  let(:args) { nil }

  before(:all) do
    puts "
    ****************************************
      TESTS ARE SLOW - DOWNLOADS PACKAGES.
    ****************************************

"
  end

  before(:each) { run("bin/mixlib-install #{command} #{args}") }

  describe "version command" do
    let(:command) { "version" }

    it "prints the mixlib-install version" do
      require "mixlib/install/version"
      expect(last_command_started).to have_output Mixlib::Install::VERSION
    end
  end

  describe "list-versions command" do
    let(:command) { "list-versions" }

    context "with valid args" do
      let(:args) { "chef stable" }

      it "prints the versions" do
        expect(last_command_started).to have_output /12.0.3/
      end
    end

    context "with invalid args" do
      let(:args) { "foo bar" }

      it "returns error message" do
        expect(last_command_started).to have_output /Unknown product name foo/
        expect(last_command_started).to have_output /Unknown channel bar/
      end
    end
  end

  describe "install-script command" do
    let(:command) { "install-script" }

    context "with no args" do
      it "returns shell script to stdout" do
        expect(last_command_started).to have_output /end of install_package.sh/
      end
    end

    context "with ps1 type" do
      let(:args) { "-t ps1" }

      it "returns powershell script to stdout" do
        expect(last_command_started).to have_output /export-modulemember -function 'Install-Project','Get-ProjectMetadata' -alias 'install'/
      end
    end

    context "with invalid type" do
      let(:args) { "-t foo" }

      it "errors an error" do
        expect(last_command_started).to have_output /type must be one of/
      end
    end

    context "with alternate endpoint" do
      let(:args) { "--endpoint https://omnitruck-custom.chef.io" }

      it "contains the new endpoint" do
        expect(last_command_started).to have_output /https:\/\/omnitruck-custom.chef.io/
      end
    end

    context "with output option" do
      let(:args) { "-o script.sh" }

      it "writes to a file" do
        expect("script.sh").to be_an_existing_file
      end
    end
  end

  describe "download command" do
    let(:command) { "download" }

    context "without args" do
      it "exits with required args error" do
        expect(last_command_started).to have_output /"mixlib-install #{command}" was called with no arguments/
      end
    end

    context "with chef product" do
      let(:args) { "chef" }

      it "downloads a chef artifact" do
        expect(last_command_started).to have_output /Download saved to/
      end
    end

    context "with url flag" do
      let(:args) { "chef --url" }

      it "outputs the url" do
        expect(last_command_started).to have_output /https:\/\/packages.chef.io\/files\/stable\/chef/
      end
    end

    context "with attributes arg" do
      let(:args) { "chef --url --attributes" }

      it "outputs the attributes" do
        expect(last_command_started).to have_output /"license": "Apache-2.0"/
      end
    end

    context "with platform arg" do
      let(:args) { "chef -p ubuntu" }

      it "fails with missing args error" do
        expect(last_command_started).to have_output /Must provide platform version and architecture when specifying a platform/
      end
    end

    context "with valid platform version and architecture" do
      let(:args) { "chef -p ubuntu -l 14.04 -a x86_64 --attributes" }
      let(:latest_version) { Mixlib::Install.available_versions("chef", "stable").last }
      let(:filename) { "chef_#{latest_version}-1_amd64.deb" }

      it "has the correct artifact" do
        require "digest"
        sha256 = Digest::SHA256.hexdigest("./tmp/aruba/#{filename}")
        expect(last_command_started).to have_output /sha256/
      end
    end

    context "with invalid platform version and architecture" do
      let(:args) { "chef -p ubuntu -l 99.99 -a x86_64" }

      it "returns no results" do
        expect(last_command_started).to have_output /No results found./
      end
    end

    context "with specified version" do
      let(:args) { "chef -v 12.0.3 " }

      it "returns the correct artifact" do
        expect(last_command_started).to have_output /chef[-_]12.0.3-1/
      end
    end

    context "with specified channel" do
      let(:args) { "chef -c current " }

      it "returns the correct artifact" do
        expect(last_command_started).to have_output /files\/current\/chef/
      end
    end

    context "with specified directory" do
      let(:args) { "chef -d mydir " }

      it "downloads to dir" do
        expect(last_command_started).to have_output /Download saved to .*mydir\/chef/
      end
    end
  end
end
