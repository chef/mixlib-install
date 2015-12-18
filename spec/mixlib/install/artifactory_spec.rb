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

context "Mixlib::Install::Backend::Artifactory", :unstable do
  let(:opts) {
    {
      channel: :unstable,
      product_name: "chef",
      product_version: :latest
    }
  }
  let(:options) { Mixlib::Install::Options.new(opts) }
  let(:artifactory) { Mixlib::Install::Backend::Artifactory.new(options) }

  context "when setting invalid endpoint" do
    it "raises a ConnectionError" do
      wrap_env("ARTIFACTORY_ENDPOINT" => "http://artifactory.example.com") do
        expect { artifactory.artifactory_info }.to raise_error Mixlib::Install::Backend::Artifactory::ConnectionError
      end
    end
  end

  context "when setting endpoint with trailing /" do
    it "it allows the training slash" do
      wrap_env("ARTIFACTORY_ENDPOINT" => "http://artifactory.chef.co/") do
        artifactory.artifactory_info
      end
    end
  end

  context "when not setting endpoint" do
    it "it uses the default" do
      wrap_env("ARTIFACTORY_ENDPOINT" => nil) do
        artifactory.artifactory_info
      end
    end
  end

  context "when using bad credentials" do
    it "raises an AuthenticationError" do
      wrap_env("ARTIFACTORY_USERNAME" => "nobodyherebythatname", "ARTIFACTORY_PASSWORD" => "secret") do
        expect { artifactory.artifactory_info }.to raise_error Mixlib::Install::Backend::Artifactory::AuthenticationError
      end
    end
  end
end
