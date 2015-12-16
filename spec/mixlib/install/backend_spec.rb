#
# Author:: Patrick Wright (<patrick@chef.io>)
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

context "Mixlib::Install::Backend" do
  let(:channel) { nil }
  let(:product_name) { nil }
  let(:product_version) { nil }
  let(:platform) { nil }
  let(:platform_version) { nil }
  let(:architecture) { nil }
  let(:shell_type) { :sh }

  let(:info) {
    Mixlib::Install.new(
      channel: channel,
      product_name: product_name,
      product_version: product_version,
      platform: platform,
      platform_version: platform_version,
      architecture: architecture,
      shell_type: shell_type
    ).artifact_info
  }

  let(:expected_protocol) { "https://" }

  shared_examples_for "the right artifact info" do
    it "gives the right url artifact info" do
      if !expected_info.key?(:url)
        expect(info.url).to match expected_protocol
      else
        expect(info.url).to match expected_info[:url]
      end
    end

    it "gives the right md5 artifact info" do
      if !expected_info.key?(:md5)
        expect(info.md5).to match(/^[0-9a-f]{32}$/)
      else
        expect(info.md5).to match expected_info[:md5] # match or eq
      end
    end

    it "gives the right sha256 artifact info" do
      if !expected_info.key?(:sha256)
        expect(info.sha256).to match(/^[0-9a-f]{64}$/)
      else
        expect(info.sha256).to match expected_info[:sha256] # match or eq
      end
    end

    it "gives the right version artifact info" do
      if !expected_info.key?(:version)
        expect(info.version).to match(/\d+.\d+.\d+/)
      else
        expect(info.version).to match expected_info[:version]
      end
    end

    it "has the right platform" do
      expect(info.platform).to eq(platform)
    end

    it "has the right platform_version" do
      expect(info.platform_version).to eq(platform_version)
    end

    it "has the right architecture" do
      expect(info.architecture).to eq(architecture)
    end
  end

  shared_examples_for "the right artifact list info" do
    it "has the correct number of platforms" do
      # Currently we have 8 platforms in stable and 7 platforms in current.
      # We can add more in the future
      expect(info.map(&:platform).uniq.length).to be >= 7

      info.each do |artifact_info|
        expect(artifact_info).to be_a(Mixlib::Install::ArtifactInfo)
      end
    end

    it "has the right version for artifacts" do
      info.each do |artifact_info|
        if expected_version.is_a? String
          expect(artifact_info.version).to eq(expected_version)
        else
          expect(artifact_info.version).to match(expected_version)
        end
      end
    end

    it "has correctly formed url" do
      info.each do |artifact_info|
        expect(artifact_info.url).to match expected_protocol
      end
    end

    it "has correctly formed sha256" do
      info.each do |artifact_info|
        expect(artifact_info.sha256).to match(/^[0-9a-f]{64}$/)
      end
    end

    it "has correctly formed md5 for artifacts" do
      info.each do |artifact_info|
        expect(artifact_info.md5).to match(/^[0-9a-f]{32}$/)
      end
    end
  end

  context "for chef" do
    let(:product_name) { "chef" }

    context "for stable" do
      let(:channel) { :stable }

      context "when p, pv and m are present" do
        let(:platform) { "mac_os_x" }
        let(:platform_version) { "10.7" }
        let(:architecture) { "x86_64" }

        context "with a full product version" do
          let(:product_version) { "12.2.1" }
          let(:expected_info) {
            {
              url: "https://opscode-omnibus-packages.s3.amazonaws.com/mac_os_x/10.7/x86_64/chef-12.2.1-1.dmg",
              md5: "d00335944b2999d0511e6db30d1e71dc",
              sha256: "53034d6e1eea0028666caee43b99f43d2ca9dd24b260bc53ae5fad1075e83923",
              version: "12.2.1"
            }
          }

          it_behaves_like "the right artifact info"
        end

        context "with a major.minor product version" do
          let(:product_version) { "12.2" }
          let(:expected_info) {
            {
              url: "https://opscode-omnibus-packages.s3.amazonaws.com/mac_os_x/10.7/x86_64/chef-12.2",
              version: "12.2"
            }
          }

          it_behaves_like "the right artifact info"
        end

        context "with a major product version" do
          let(:product_version) { "12" }
          let(:expected_info) {
            {
              url: "https://opscode-omnibus-packages.s3.amazonaws.com/mac_os_x/10.7/x86_64/chef-12",
              version: "12"
            }
          }

          it_behaves_like "the right artifact info"
        end

        context "with :latest version keyword" do
          let(:product_version) { :latest }
          let(:expected_info) { {} }

          it_behaves_like "the right artifact info"
        end
      end

      context "when p, pv and m are not present" do
        context "with a full product version" do
          let(:product_version) { "12.4.3" }
          let(:expected_version) { "12.4.3" }

          it_behaves_like "the right artifact list info"
        end

        context "with a major.minor product version" do
          let(:product_version) { "12.1" }
          let(:expected_version) { "12.1.2" }

          it_behaves_like "the right artifact list info"
        end

        context "with a major product version" do
          let(:product_version) { "12" }
          let(:expected_version) { /^12.\d.\d/ }

          it_behaves_like "the right artifact list info"
        end

        context "with latest version keyword" do
          let(:product_version) { "latest" }
          let(:expected_version) { /\d.\d.\d/ }

          it_behaves_like "the right artifact list info"
        end
      end
    end

    context "for current" do
      let(:channel) { :current }

      context "when p, pv and m are present" do
        let(:platform) { "mac_os_x" }
        let(:platform_version) { "10.9" }
        let(:architecture) { "x86_64" }

        context "with an integration product version" do
          let(:product_version) { "12.4.3+20151006083011" }
          let(:expected_info) {
            {
              url: "https://opscode-omnibus-packages-current.s3.amazonaws.com/mac_os_x/10.9/x86_64/chef-12.4.3%2B20151006083011-1.dmg",
              md5: "103f98e4b72407245bdf44a0357fd8e4",
              sha256: "c74cac0ecdef969820770c6e21fcf249d623dba40ea9bacdb2de5cd3bfbeedaf",
              version: "12.4.3+20151006083011"
            }
          }

          it_behaves_like "the right artifact info"
        end

        context "with a major.minor.patch version" do
          let(:product_version) { "12.4.3" }
          let(:expected_info) {
            {
              url: "https://opscode-omnibus-packages-current.s3.amazonaws.com/mac_os_x/10.9/x86_64/chef-12.4.3%2B",
              version: "12.4.3+"
            }
          }

          it_behaves_like "the right artifact info"
        end

        context "with a major.minor product version" do
          let(:product_version) { "12.4" }
          let(:expected_info) {
            {
              url: "https://opscode-omnibus-packages-current.s3.amazonaws.com/mac_os_x/10.9/x86_64/chef-12.4",
              version: "12.4"
            }
          }

          it_behaves_like "the right artifact info"
        end

        context "with a major product version" do
          let(:product_version) { "12" }
          let(:expected_info) {
            {
              url: "https://opscode-omnibus-packages-current.s3.amazonaws.com/mac_os_x/10.9/x86_64/chef-12",
              version: "12"
            }
          }

          it_behaves_like "the right artifact info"
        end

        context "with latest version keyword" do
          let(:product_version) { :latest }
          let(:expected_info) { {} }

          it_behaves_like "the right artifact info"
        end
      end

      context "when p, pv and m are not present" do
        context "with a full product version" do
          let(:product_version) { "12.4.3+20151006083011" }
          let(:expected_version) { "12.4.3+20151006083011" }

          it_behaves_like "the right artifact list info"
        end

        context "with a major.minor.patch product version" do
          let(:product_version) { "12.4.3" }
          let(:expected_version) { /^12.4.3\+[0-9]{14}$/ }

          it_behaves_like "the right artifact list info"
        end

        context "with a major.minor product version" do
          let(:product_version) { "12.4" }
          let(:expected_version) { /^12.4.\d/ }

          it_behaves_like "the right artifact list info"
        end

        context "with a major product version" do
          let(:product_version) { "12" }
          let(:expected_version) { /^12.\d.\d/ }

          it_behaves_like "the right artifact list info"
        end

        context "with latest version keyword" do
          let(:product_version) { "latest" }
          let(:expected_version) { /^\d\d.\d.\d/ }

          it_behaves_like "the right artifact list info"
        end
      end
    end

    context "for unstable", :unstable do
      let(:channel) { :unstable }
      let(:expected_protocol) { "http://" }

      context "when p, pv and m are not present" do
        context "with an integration product version" do
          let(:product_version) { "12.5.1+20151210002019" }
          let(:expected_version) { "12.5.1+20151210002019" }

          it_behaves_like "the right artifact list info"
        end
      end

      context "when p, pv and m are present" do
        context "for mac" do
          let(:platform) { "mac_os_x" }
          let(:platform_version) { "10.9" }
          let(:architecture) { "x86_64" }

          context "with an integration product version" do
            let(:product_version) { "12.5.1+20151210002019" }
            let(:expected_info) {
              {
                url: "http://artifactory.chef.co/omnibus-unstable-local/com/getchef/chef/12.5.1+20151210002019/mac_os_x/10.9/chef-12.5.1+20151210002019-1.dmg",
                sha256: "9791d09e2df02a3bb008f0e9efb52eb97e348193f45792ea4b367f156eac5a81",
                md5: "56fc059c547afe3eb511221a337e9fd9"
              }
            }

            it_behaves_like "the right artifact info"
          end

          context "with 'latest' product version" do
            let(:product_version) { :latest }
            let(:expected_info) { {} }
            let(:expected_version) { /^\d\d.\d.\d\+[0-9]{14}$/ }

            it_behaves_like "the right artifact info"
          end
        end

        context "for windows" do
          let(:platform) { "windows" }
          let(:platform_version) { "2012r2" }
          let(:architecture) { "i386" }
          let(:product_version) { "12.5.1+20151210002019" }
          let(:expected_info) {
            {
              url: "http://artifactory.chef.co/omnibus-unstable-local/com/getchef/chef/12.5.1+20151210002019/windows/2012r2/chef-client-12.5.1+20151210002019-1-x86.msi",
              sha256: "3bc8b4b2c80541b04060883ce131cdc7c83c5b275cf202f4199fa621568faaf6",
              md5: "b23f4801a54ba3442e72192d390f37dc"
            }
          }

          it_behaves_like "the right artifact info"

          it "does not have storage/api in the url" do
            expect(info.url).not_to include("storage/api")
          end
        end

        context "for latest version"  do
          let(:product_version) { :latest }
          let(:expected_info) { {} }
          let(:expected_version) { /^\d\d.\d.\d\+[0-9]{14}$/ }

          it_behaves_like "the right artifact list info"
        end
      end
    end
  end
end
