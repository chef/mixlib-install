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

  context "for license_id option" do
    let(:product_name) { "chef" }
    let(:channel) { :stable }
    let(:license_id) { "test-license-123" }

    it "accepts license_id parameter" do
      mi = Mixlib::Install.new(product_name: product_name, channel: channel, license_id: license_id)
      expect(mi.options.license_id).to eq license_id
    end

    it "allows nil license_id" do
      mi = Mixlib::Install.new(product_name: product_name, channel: channel)
      expect(mi.options.license_id).to be_nil
    end

    it "allows empty license_id" do
      mi = Mixlib::Install.new(product_name: product_name, channel: channel, license_id: "")
      expect(mi.options.license_id).to eq ""
    end
  end

  context "for trial API defaults" do
    let(:product_name) { "chef" }

    context "with free- license_id" do
      let(:license_id) { "free-trial-abc-123" }

      it "defaults to stable channel when current channel is specified" do
        expect do
          mi = Mixlib::Install.new(product_name: product_name, channel: :current, license_id: license_id)
          expect(mi.options.channel).to eq :stable
        end.to output(/WARNING: Trial API only supports 'stable' channel. Changing from 'current' to 'stable'/).to_stderr
      end

      it "defaults to latest version when specific version is specified" do
        expect do
          mi = Mixlib::Install.new(product_name: product_name, channel: :stable, product_version: "15.0.0", license_id: license_id)
          expect(mi.options.product_version).to eq :latest
        end.to output(/WARNING: Trial API only supports 'latest' version. Changing from '15.0.0' to 'latest'/).to_stderr
      end

      it "defaults both channel and version with two warnings" do
        expect do
          mi = Mixlib::Install.new(product_name: product_name, channel: :unstable, product_version: "14.5.1", license_id: license_id)
          expect(mi.options.channel).to eq :stable
          expect(mi.options.product_version).to eq :latest
        end.to output(/WARNING: Trial API only supports 'stable' channel.*WARNING: Trial API only supports 'latest' version/m).to_stderr
      end

      it "does not warn when stable channel and latest version are already set" do
        expect do
          mi = Mixlib::Install.new(product_name: product_name, channel: :stable, product_version: :latest, license_id: license_id)
          expect(mi.options.channel).to eq :stable
          expect(mi.options.product_version).to eq :latest
        end.not_to output.to_stderr
      end

      it "does not warn when stable channel and latest version string are already set" do
        expect do
          mi = Mixlib::Install.new(product_name: product_name, channel: :stable, product_version: "latest", license_id: license_id)
          expect(mi.options.channel).to eq :stable
          expect(mi.options.product_version).to eq "latest"
        end.not_to output.to_stderr
      end
    end

    context "with trial- license_id" do
      let(:license_id) { "trial-xyz-456" }

      it "defaults to stable channel when unstable channel is specified" do
        expect do
          mi = Mixlib::Install.new(product_name: product_name, channel: :unstable, license_id: license_id)
          expect(mi.options.channel).to eq :stable
        end.to output(/WARNING: Trial API only supports 'stable' channel. Changing from 'unstable' to 'stable'/).to_stderr
      end

      it "defaults to latest version when specific version is specified" do
        expect do
          mi = Mixlib::Install.new(product_name: product_name, channel: :stable, product_version: "16.2.50", license_id: license_id)
          expect(mi.options.product_version).to eq :latest
        end.to output(/WARNING: Trial API only supports 'latest' version. Changing from '16.2.50' to 'latest'/).to_stderr
      end
    end

    context "with commercial license_id" do
      let(:license_id) { "commercial-license-789" }

      it "does not default channel" do
        expect do
          mi = Mixlib::Install.new(product_name: product_name, channel: :current, license_id: license_id)
          expect(mi.options.channel).to eq :current
        end.not_to output.to_stderr
      end

      it "does not default version" do
        expect do
          mi = Mixlib::Install.new(product_name: product_name, channel: :stable, product_version: "17.0.0", license_id: license_id)
          expect(mi.options.product_version).to eq "17.0.0"
        end.not_to output.to_stderr
      end
    end

    context "without license_id" do
      it "does not default channel" do
        expect do
          mi = Mixlib::Install.new(product_name: product_name, channel: :current)
          expect(mi.options.channel).to eq :current
        end.not_to output.to_stderr
      end

      it "does not default version" do
        expect do
          mi = Mixlib::Install.new(product_name: product_name, channel: :stable, product_version: "18.1.0")
          expect(mi.options.product_version).to eq "18.1.0"
        end.not_to output.to_stderr
      end
    end
  end
end
