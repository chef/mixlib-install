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

context "Mixlib::Install::Backend", :vcr do
  let(:channel) { nil }
  let(:product_name) { nil }
  let(:product_version) { nil }
  let(:platform) { nil }
  let(:platform_version) { nil }
  let(:architecture) { nil }

  let(:expected_info) { nil }

  let(:info) {
    Mixlib::Install.new(
      channel: channel,
      product_name: product_name,
      product_version: product_version,
      platform: platform,
      platform_version: platform_version,
      architecture: architecture
    ).artifact_info
  }

  let(:available_versions) {
    Mixlib::Install.new(
      channel: channel,
      product_name: product_name
    ).available_versions
  }

  def check_url(url)
    if expected_info && !expected_info.key?(:url)
      expect(url).to match /#{expected_info[:url]}/
    else
      if Mixlib::Install.artifactory_backend?
        expect(url).to include(ENV["ARTIFACTORY_ENDPOINT"] || Mixlib::Install::Backend::Artifactory::ENDPOINT)
      else
        expect(url).to include(ENV["PACKAGE_ROUTER_ENDPOINT"] || Mixlib::Install::Backend::PackageRouter::ENDPOINT)
      end
    end
  end

  def check_sha256(sha256)
    if expected_info && expected_info.key?(:sha256)
      expect(sha256).to match expected_info[:sha256] # match or eq
    else
      expect(sha256).to match(/^[0-9a-f]{64}$/)
    end
  end

  def check_version(version)
    if expected_info && expected_info.key?(:version)
      expect(version).to match expected_info[:version]
    else
      expect(version).to match(/\d+.\d+.\d+/)
    end
  end

  def check_platform_info(data)
    expect(data.platform).to eq(platform)
    expect(data.platform_version).to eq(platform_version)
    expect(data.architecture).to eq(architecture)
  end

  shared_examples_for "the right artifact info" do
    it "has the right properties" do
      check_url(info.url)
      check_sha256(info.sha256)
      check_version(info.version)
    end

    it "has the right platform info" do
      check_platform_info(info)
    end
  end

  shared_examples_for "the right artifact list info" do
    it "has the correct number of platforms" do
      # Currently we have 7 platforms in stable and 6 platforms in current.
      # We can add more in the future
      expect(info.map(&:platform).uniq.length).to be >= 6

      info.each do |artifact_info|
        expect(artifact_info).to be_a(Mixlib::Install::ArtifactInfo)
      end
    end

    it "has the right properties for artifacts" do
      info.each do |artifact_info|
        check_url(artifact_info.url)
        check_sha256(artifact_info.sha256)
        check_version(artifact_info.version)
      end
    end
  end

  context "for stable channel with specific version" do
    let(:product_name) { "chef" }
    let(:channel) { :stable }
    let(:product_version) { "12.2.1" }

    context "without platform info" do
      let(:expected_info) {
        {
          version: "12.2.1",
        }
      }

      it_behaves_like "the right artifact list info"
    end

    context "with platform info" do
      let(:platform) { "mac_os_x" }
      let(:platform_version) { "10.10" }
      let(:architecture) { "x86_64" }

      let(:expected_info) {
        {
          url: "/stable/mac_os_x/10.10/chef-12.2.1-1.dmg",
          sha256: "53034d6e1eea0028666caee43b99f43d2ca9dd24b260bc53ae5fad1075e83923",
          version: "12.2.1",
        }
      }

      it_behaves_like "the right artifact info"
    end
  end

  context "for stable channel with :latest" do
    let(:product_name) { "chef" }
    let(:channel) { :stable }
    let(:product_version) { :latest }

    context "without platform info" do
      it_behaves_like "the right artifact list info"
    end

    context "with platform info" do
      let(:platform) { "ubuntu" }
      let(:platform_version) { "14.04" }
      let(:architecture) { "x86_64" }

      it_behaves_like "the right artifact info"
    end
  end

  context "for current channel with :latest" do
    let(:product_name) { "chef" }
    let(:channel) { :current }
    let(:product_version) { :latest }

    context "without platform info" do
      it_behaves_like "the right artifact list info"
    end

    context "with platform info" do
      let(:platform) { "ubuntu" }
      let(:platform_version) { "14.04" }
      let(:architecture) { "x86_64" }

      it_behaves_like "the right artifact info"
    end
  end

  context "for unstable channel with :latest" do
    let(:product_name) { "chef" }
    let(:channel) { :unstable }
    let(:product_version) { :latest }

    context "without platform info" do
      it_behaves_like "the right artifact list info"
    end

    context "with platform info" do
      let(:platform) { "ubuntu" }
      let(:platform_version) { "14.04" }
      let(:architecture) { "x86_64" }

      it_behaves_like "the right artifact info"
    end
  end

  context "available_versions" do
    let(:product_name) { "chef" }

    context "with :unstable channel" do
      let(:channel) { :unstable }

      it "returns the list of available versions" do
        ["12.13.30+20160809181757", "12.13.33+20160810230453", "12.13.33+20160811154116", "12.13.36+20160811220629", "12.13.36+20160811223655", "12.13.36+20160811235050", "12.13.36+20160812051326", "12.13.30+20160812195955", "12.13.40", "12.13.42", "12.13.41+20160816160510", "12.14.1"].each do |v|
          expect(available_versions).to include(v)
        end
      end
    end
  end
end
