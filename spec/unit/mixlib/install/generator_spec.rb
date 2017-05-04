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
require "mixlib/install/version"

context "Mixlib::Install::Generator", :vcr do
  let(:channel) { nil }
  let(:product_version) { "latest" }
  let(:add_options) { {} }

  let(:options) do
    {
      product_name: "chef",
      channel: channel,
      product_version: product_version,
    }
  end

  let(:install_script) do
    options.merge!(add_options)
    Mixlib::Install.new(options).install_command
  end

  shared_examples_for "the correct sh script" do
    it "generates an sh script" do
      expect(install_script).to be_a(String)
      expect(install_script).to start_with("#!/bin/sh")
      expect(install_script).to include('install_file $filetype "$download_filename"')
    end
  end

  context "for :unstable channel" do
    let(:channel) { :unstable }
    let(:product_version) { "12.5.1+20151210002019" }

    context "default shell type" do
      it_behaves_like "the correct sh script"
    end
  end

  context "for :stable channel" do
    let(:channel) { :stable }

    context "default shell type" do
      it_behaves_like "the correct sh script"
    end

    context "sh shell type" do
      let(:add_options) do
        {
          shell_type: :sh,
        }
      end

      it_behaves_like "the correct sh script"
    end

    context "for windows" do
      shared_examples_for "the correct ps1 script" do
        it "generates a ps1 script" do
          expect(install_script).to be_a(String)
          expect(install_script).to start_with("new-module -name Omnitruck -scriptblock")
          expect(install_script).to include("set-alias install -value Install-Project")
        end
      end

      context "when platform is set" do
        let(:add_options) do
          {
            platform: "windows",
            platform_version: "2012r2",
            architecture: "x86_64",
          }
        end

        it_behaves_like "the correct ps1 script"

        it "adds an architecture param" do
          expect(install_script).to match(/install -project #{options[:product_name]} -version .* -channel #{options[:channel]} -architecture #{options[:architecture]}\n/)
        end

      end

      context "when shell_type is set" do
        let(:add_options) do
          {
            shell_type: :ps1,
          }
        end

        it_behaves_like "the correct ps1 script"

        it "adds ommits the architecture param" do
          expect(install_script).to match(/install -project #{options[:product_name]} -version .* -channel #{options[:channel]}\n/)
        end
      end
    end
  end

  context "for user agent headers" do
    let(:context) { {} }

    context "when using class method" do
      let(:install_script) { Mixlib::Install.install_sh(context) }

      context "without user_agent_headers" do
        it "sets the default agent header" do
          expect(install_script).to match(/"User-Agent: mixlib-install\/#{Mixlib::Install::VERSION}"/)
        end
      end

      context "when it excludes mixlib-install agent header" do
        let(:context) do
          { user_agent_headers: %w{testheader/1.2.3} }
        end

        it "sets adds the default headers" do
          expect(install_script).to match(/"User-Agent: mixlib-install\/#{Mixlib::Install::VERSION} testheader\/1.2.3"/)
        end
      end

      context "when it includes mixlib-install agent header" do
        let(:context) do
          { user_agent_headers: %W{mixlib-install/#{Mixlib::Install::VERSION} testheader/4.5.6} }
        end

        it "doesn't duplicate the default header" do
          expect(install_script).to match(/"User-Agent: mixlib-install\/#{Mixlib::Install::VERSION} testheader\/4.5.6"/)
        end
      end
    end

    context "when using instance method" do
      let(:channel) { :stable }

      context "without user_agent_headers set" do
        it "sets the default agent header" do
          expect(install_script).to match(/"User-Agent: mixlib-install\/#{Mixlib::Install::VERSION}"/)
        end
      end

      context "with user_agent_headers set" do
        let(:add_options) do
          { user_agent_headers: ["testheader/11.22.33"] }
        end

        it "sets adds the additional headers" do
          expect(install_script).to match(/"User-Agent: mixlib-install\/#{Mixlib::Install::VERSION} testheader\/11.22.33"/)
        end
      end
    end
  end

  context "when setting install_command_options" do
    let(:channel) { :stable }

    context "for powershell install params" do
      let(:install_command_options) do
        { http_proxy: "http://sam:iam@greeneggsandham:1111" }
      end

      let(:add_options) do
        {
          install_command_options: install_command_options,
          shell_type: :ps1,
        }
      end

      it "#install_command adds http_proxy param" do
        expect(install_script).to match(/install -project .* -version .* -channel .* -http_proxy '#{install_command_options[:http_proxy]}'\n/)
      end
    end

    context "for bourne install params" do
      let(:install_command_options) do
        {
          cmdline_dl_dir: "/hereiam",
          download_url_override: "https://packages.chef.ioo/files/stable/chef/12.19.36/debian/8/chef_12.19.36-1_amd64.deb",
          checksum: "292651ac21e093a40446da6b9a9b075ad31be6991a6f7ab63d5b6c2edabaa03c",
        }
      end

      let(:add_options) do
        {
          install_command_options: install_command_options,
        }
      end

      it "adds cmdline_dl_dir var" do
        expect(install_script).to match(/cmdline_dl_dir='#{install_command_options[:cmdline_dl_dir]}'/)
      end

      it "adds download_url_override var" do
        expect(install_script).to match(/download_url_override='#{install_command_options[:download_url_override]}'/)
      end

      it "adds checksum var" do
        expect(install_script).to match(/checksum='#{install_command_options[:checksum]}'/)
      end
    end
  end
end
