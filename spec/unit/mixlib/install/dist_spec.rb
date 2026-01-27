#
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
require "mixlib/install/dist"

describe Mixlib::Install::Dist do
  describe ".trial_license?" do
    context "with free- prefix" do
      it "returns true for free-trial-123" do
        expect(Mixlib::Install::Dist.trial_license?("free-trial-123")).to be true
      end

      it "returns true for free-abc-xyz" do
        expect(Mixlib::Install::Dist.trial_license?("free-abc-xyz")).to be true
      end
    end

    context "with trial- prefix" do
      it "returns true for trial-xyz-456" do
        expect(Mixlib::Install::Dist.trial_license?("trial-xyz-456")).to be true
      end

      it "returns true for trial-123" do
        expect(Mixlib::Install::Dist.trial_license?("trial-123")).to be true
      end
    end

    context "with commercial license" do
      it "returns false for commercial-license-789" do
        expect(Mixlib::Install::Dist.trial_license?("commercial-license-789")).to be false
      end

      it "returns false for standard-license-abc" do
        expect(Mixlib::Install::Dist.trial_license?("standard-license-abc")).to be false
      end
    end

    context "with nil or empty values" do
      it "returns false for nil" do
        expect(Mixlib::Install::Dist.trial_license?(nil)).to be false
      end

      it "returns false for empty string" do
        expect(Mixlib::Install::Dist.trial_license?("")).to be false
      end
    end

    context "with nil or empty" do
      it "returns false for nil" do
        expect(Mixlib::Install::Dist.trial_license?(nil)).to be false
      end

      it "returns false for empty string" do
        expect(Mixlib::Install::Dist.trial_license?("")).to be false
      end
    end
  end

  describe ".commercial_license?" do
    context "with commercial license" do
      it "returns true for commercial-license-789" do
        expect(Mixlib::Install::Dist.commercial_license?("commercial-license-789")).to be true
      end

      it "returns true for any non-trial/free license" do
        expect(Mixlib::Install::Dist.commercial_license?("my-license-key")).to be true
      end
    end

    context "with trial license" do
      it "returns false for free-trial-123" do
        expect(Mixlib::Install::Dist.commercial_license?("free-trial-123")).to be false
      end

      it "returns false for trial-xyz-456" do
        expect(Mixlib::Install::Dist.commercial_license?("trial-xyz-456")).to be false
      end
    end

    context "with nil or empty" do
      it "returns false for nil" do
        expect(Mixlib::Install::Dist.commercial_license?(nil)).to be false
      end

      it "returns false for empty string" do
        expect(Mixlib::Install::Dist.commercial_license?("")).to be false
      end
    end
  end

  describe "install directory constants" do
    it "defines OMNIBUS_WINDOWS_INSTALL_DIR" do
      expect(Mixlib::Install::Dist::OMNIBUS_WINDOWS_INSTALL_DIR).to eq("opscode")
    end

    it "defines OMNIBUS_LINUX_INSTALL_DIR" do
      expect(Mixlib::Install::Dist::OMNIBUS_LINUX_INSTALL_DIR).to eq("/opt")
    end

    it "defines HABITAT_WINDOWS_INSTALL_DIR" do
      expect(Mixlib::Install::Dist::HABITAT_WINDOWS_INSTALL_DIR).to eq("hab\\pkgs")
    end

    it "defines HABITAT_LINUX_INSTALL_DIR" do
      expect(Mixlib::Install::Dist::HABITAT_LINUX_INSTALL_DIR).to eq("/hab/pkgs")
    end
  end
end
