#
# Author:: Patrick Wright (<patrick@chef.io>)
# Copyright:: Copyright (c) 2015-2018 Chef Software, Inc.
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
  let(:user_agent_headers) { nil }

  context "for platform_version_compatibility_mode option" do
    let(:product_name) { "chef" }
    let(:channel) { :stable }

    context "when not setting platform info" do
      it "is set to true" do
        mi = Mixlib::Install.new(product_name: product_name, channel: channel)
        expect(mi.options.platform_version_compatibility_mode).to be true
      end
    end

    context "when setting platform info" do
      let(:platform) { "ubuntu" }
      let(:platform_version) { "13.04" }
      let(:architecture) { "x86_64" }

      it "is set to false" do
        mi = Mixlib::Install.new(product_name: product_name, channel: channel, platform: platform, platform_version: platform_version, architecture: architecture)
        expect(mi.options.platform_version_compatibility_mode).to be false
      end

      context "when setting platform_version_compatibility_mode true" do
        it "is set to true" do
          mi = Mixlib::Install.new(product_name: product_name, channel: channel, platform: platform, platform_version: platform_version, architecture: architecture, platform_version_compatibility_mode: true)
          expect(mi.options.platform_version_compatibility_mode).to be true
        end
      end
    end
  end

  context "for invalid architecture option" do
    let(:architecture) { "foo" }

    it "raises unknown architecture error" do
      expect { Mixlib::Install.new(architecture: architecture) }.to raise_error(Mixlib::Install::Options::InvalidOptions, /Unknown architecture foo/)
    end
  end

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
    let(:channel) { :stable }

    context "with platform" do
      let(:platform) { "ubuntu" }

      it "raises platform options error" do
        expect { Mixlib::Install.new(product_name: product_name, channel: channel, platform: platform) }.to raise_error(Mixlib::Install::Options::InvalidOptions, /Must provide platform \(-p\), platform version \(-l\) and architecture \(-a\) when specifying any platform details/)
      end

      context "and with platform version" do
        let(:platform_version) { "14.04" }

        it "raises platform options error" do
          expect { Mixlib::Install.new(product_name: product_name, channel: channel, platform: platform, platform_version: platform_version) }.to raise_error(Mixlib::Install::Options::InvalidOptions, /Must provide platform \(-p\), platform version \(-l\) and architecture \(-a\) when specifying any platform details/)
        end
      end
    end

    context "with architecture" do
      let(:architecture) { "i386" }

      it "raises platform options error" do
        expect { Mixlib::Install.new(product_name: product_name, channel: channel, architecture: architecture) }.to raise_error(Mixlib::Install::Options::InvalidOptions, /Must provide platform \(-p\), platform version \(-l\) and architecture \(-a\) when specifying any platform details/)
      end
    end
  end

  context "for shell type options" do
    let(:shell_type) { :foo }

    it "raises invalid shell type error" do
      expect { Mixlib::Install.new(shell_type: shell_type) }.to raise_error(Mixlib::Install::Options::InvalidOptions, /Unknown shell type/)
    end
  end

  context "for user_agents option" do
    context "passed as a string" do
      let(:user_agent_headers) { "myString" }

      it "raises an error" do
        expect { Mixlib::Install.new(product_name: "chef", channel: :stable, user_agent_headers: user_agent_headers) }.to raise_error(Mixlib::Install::Options::InvalidOptions, /user_agent_headers must be an Array/)
      end
    end

    context "headers passed with spaces" do
      let(:user_agent_headers) { ["a", "b c"] }

      it "raises an error" do
        expect { Mixlib::Install.new(product_name: "chef", channel: :stable, user_agent_headers: user_agent_headers) }.to raise_error(Mixlib::Install::Options::InvalidOptions, /user agent headers can not have spaces/)
      end
    end
  end
end
