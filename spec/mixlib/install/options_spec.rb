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

context "Mixlib::Install::Options" do
  let(:channel) { nil }
  let(:product_name) { nil }
  let(:product_version) { nil }
  let(:platform) { nil }
  let(:platform_version) { nil }
  let(:architecture) { nil }
  let(:shell_type) { nil }

  context "for invalid product name option" do
    let(:product_name) { "foo" }

    it "raises unknown product name error" do
      expect { Mixlib::Install.new(product_name: product_name) }.to raise_error(Mixlib::Install::Options::InvalidOptions, /Unknown product name foo/)
    end
  end

  context "for invalid channel option" do
    let(:channel) { :foo }

    it "raises unknown channel error" do
      expect { Mixlib::Install.new(channel: channel) }.to raise_error(Mixlib::Install::Options::InvalidOptions, /Unknown channel foo/)
    end
  end

  context "for platform options" do
    let(:product_name) { "chef" }
    let(:product_version) { "1.2.3" }

    context "for shell type options" do
      let(:shell_type) { :foo }

      it "raises invalid shell type error" do
        expect { Mixlib::Install.new(shell_type: shell_type) }.to raise_error(Mixlib::Install::Options::InvalidOptions, /Unknown shell type/)
      end
    end
  end
end
