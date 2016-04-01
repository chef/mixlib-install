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

context "Mixlib::Install::Generator" do
  let(:channel) { nil }
  let(:product_version) { "latest" }
  let(:add_options) { {} }

  let(:options) {
    {
      product_name: "chef",
      channel: channel,
      product_version: product_version,
    }
  }

  let(:install_script) {
    options.merge!(add_options)
    Mixlib::Install.new(options).install_command
  }

  shared_examples_for "the correct sh script" do
    it "generates an sh script" do
      expect(install_script).to be_a(String)
      expect(install_script).to start_with("#!/bin/sh")
      expect(install_script).to include('install_file $filetype "$download_filename"')
    end
  end

  context "for :unstable channel", :vcr do
    let(:channel) { :unstable }
    let(:product_version) { "12.5.1+20151210002019" }

    context "default shell type" do
      it_behaves_like "the correct sh script"

      it "contains artifactory urls" do
        expect(install_script).to include('artifact_info_for_platform="$tmp_dir/artifact_info/$platform/$platform_version/$machine/artifact_info"
')
      end
    end
  end

  context "for :stable channel" do
    let(:channel) { :stable }

    context "default shell type" do
      it_behaves_like "the correct sh script"
    end

    context "sh shell type" do
      let(:add_options) {
        {
          shell_type: :sh,
        }
      }

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
        let(:add_options) {
          {
            platform: "windows",
            platform_version: "2012r2",
            architecture: "x86_64",
          }
        }

        it_behaves_like "the correct ps1 script"

        it "adds an architecture param" do
          expect(install_script).to match(/install -project #{options[:product_name]} -version .* -channel #{options[:channel]} -architecture #{options[:architecture]}\n/)
        end

      end

      context "when shell_type is set" do
        let(:add_options) {
          {
            shell_type: :ps1,
          }
        }

        it_behaves_like "the correct ps1 script"

        it "adds ommits the architecture param" do
          expect(install_script).to match(/install -project #{options[:product_name]} -version .* -channel #{options[:channel]}\n/)
        end
      end
    end
  end
end
