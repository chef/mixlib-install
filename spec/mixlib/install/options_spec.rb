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
    let(:base_options) {
      {
        channel: channel,
        product_name: product_name,
        product_version: product_version,
      }
    }
    let(:options) {}

    shared_examples_for "invalid platform options" do
      it "raises InvalidOptions" do
        expect { Mixlib::Install.new(options) }.to raise_error(Mixlib::Install::Options::InvalidOptions, /platform, platform version, and architecture/)
      end
    end

    context "for stable channel" do
      let(:channel) { :stable }

      context "for setting missing platform options" do
        it "raises InvalidOptions" do
          installer = Mixlib::Install.new(base_options)
          expect { installer.options.set_platform_info({ platform: "foo" }) }.to raise_error(Mixlib::Install::Options::InvalidOptions, /platform, platform version, and architecture/)
        end
      end

      context "without platform version" do
        let(:options) { base_options.merge(platform: platform, architecture: "1") }

        it_behaves_like "invalid platform options"
      end

      context "without architecture" do
        let(:options) { base_options.merge(platform: platform, platform_version: "1") }

        it_behaves_like "invalid platform options"
      end

      context "without platform" do
        let(:options) { base_options.merge(architecture: "1", platform_version: "1") }

        it_behaves_like "invalid platform options"
      end

      context "without any platform info" do
        it "does not raise an error" do
          expect { Mixlib::Install.new(base_options) }.to_not raise_error
        end
      end
    end

    context "for unstable channel", :unstable do
      let(:channel) { :unstable }

      it "raises invalid artifactory env vars error" do
        wrap_env("ARTIFACTORY_USERNAME" => nil, "ARTIFACTORY_PASSWORD" => nil) do
          expect { Mixlib::Install.new(base_options) }.to raise_error(Mixlib::Install::Options::ArtifactoryCredentialsNotFound)
        end
      end
    end

    context "for shell type options" do
      let(:shell_type) { :foo }

      it "raises invalid shell type error" do
        expect { Mixlib::Install.new(shell_type: shell_type) }.to raise_error(Mixlib::Install::Options::InvalidOptions, /Unknown shell type/)
      end
    end
  end
end
