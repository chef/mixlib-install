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
require "mixlib/install/backend/artifactory"

context "Mixlib::Install::Backend::Artifactory", focus: true do
  let(:product_name) { "chef" }
  let(:product_version) { nil }
  let(:channel) { nil }

  let(:opts) {
    {
      product_name: product_name,
      product_version: product_version,
      channel: channel
    }
  }

  let(:options) { Mixlib::Install::Options.new(opts) }

  let(:artifactory) { Mixlib::Install::Backend::Artifactory.new(options) }

  context "with unstable channel" do
    let(:channel) { :unstable }
    let(:product_version) { "12.5.1+20151210002019" }

    it "pulls unstable artifacts" do
      puts artifactory.info
      # expect(artifactory.info.size).to be > 0
    end
  end

  context "with stable channel" do
    let(:channel) { :stable }
    let(:product_version) { "12.5.1" }

    it "pulls stable artifacts" do
      puts artifactory.info
      # expect(artifactory.info.size).to be > 0
    end
  end

  context "with current channel" do
    let(:channel) { :current }
    let(:product_version) { "12.5.1+20151210002019" }

    it "pulls current artifacts" do
      puts artifactory.info
      # expect(artifactory.info.size).to be > 0
    end
  end

end
