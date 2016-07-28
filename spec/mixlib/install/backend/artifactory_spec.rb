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

require "mixlib/install/options"
require "mixlib/install/backend/artifactory"

context "Mixlib::Install::Backend::Artifactory", :vcr do
  let(:opts) {
    {
      channel: :unstable,
      product_name: "chef",
      product_version: :latest,
      platform: "ubuntu",
      platform_version: "14.04",
      architecture: "x86_64",
    }
  }
  let(:options) { Mixlib::Install::Options.new(opts) }
  let(:artifactory) { Mixlib::Install::Backend::Artifactory.new(options) }
  let(:query) { "item.find({\"@omnibus.project\": \"chef\"})" }

  context "when setting invalid endpoint" do
    it "raises a ConnectionError" do
      wrap_env("ARTIFACTORY_ENDPOINT" => "http://artifactory.example.archinstall/") do
        expect { artifactory.artifactory_query(query) }.to raise_error Mixlib::Install::Backend::Artifactory::ConnectionError
      end
    end
  end

  context "when setting endpoint with trailing /" do
    it "it allows the training slash" do
      custom_endpoint = if Mixlib::Install.unified_backend?
                          "https://packages-acceptance.chef.io/"
                        else
                          "http://artifactory.chef.co/"
                        end

      wrap_env("ARTIFACTORY_ENDPOINT" => custom_endpoint) do
        artifactory.info
      end
    end
  end

  context "when not setting endpoint" do
    it "it uses the default" do
      wrap_env("ARTIFACTORY_ENDPOINT" => nil) do
        artifactory.info
      end
    end
  end

  context "when an querying artifact" do
    it "does not return metadata.json" do
      expect(artifactory.info).to be_a Mixlib::Install::ArtifactInfo
      expect(artifactory.info.url).not_to include("metadata.json")
    end
  end

  context "when querying automate" do
    let(:opts) {
      {
        channel: :unstable,
        product_name: "automate",
        product_version: :latest,
        platform: "ubuntu",
        platform_version: "14.04",
        architecture: "x86_64",
      }
    }

    it "uses the omnibus project name" do
      expect(artifactory.info).to be_a Mixlib::Install::ArtifactInfo
      expect(artifactory.info.url).to match "delivery"
    end
  end

  context "when querying compliance" do
    let(:opts) {
      {
        channel: :current,
        product_name: "compliance",
        product_version: :latest,
        platform: "ubuntu",
        platform_version: "14.04",
        architecture: "x86_64",
      }
    }

    it "uses the omnibus project name" do
      expect(artifactory.info).to be_a Mixlib::Install::ArtifactInfo
      expect(artifactory.info.url).to match "chef-compliance"
    end
  end

  context "when querying chef-server" do
    let(:opts) {
      {
        channel: :unstable,
        product_name: "chef-server",
        product_version: :latest,
        platform: "ubuntu",
        platform_version: "14.04",
        architecture: "x86_64",
      }
    }

    it "uses the omnibus project name" do
      expect(artifactory.info).to be_a Mixlib::Install::ArtifactInfo
      expect(artifactory.info.url).to match "chef-server-core"
    end
  end
end
