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
require "mixlib/install/generator/base"
require "mixlib/install/options"

describe Mixlib::Install::Generator::Base do
  let(:options) do
    Mixlib::Install::Options.new(
      product_name: "chef",
      channel: :stable,
      product_version: "17.0.0"
    )
  end

  let(:generator) { described_class.new(options) }

  describe "#initialize" do
    it "creates a new generator with options" do
      expect(generator).to be_a(described_class)
      expect(generator.options).to eq(options)
    end
  end

  describe "#options" do
    it "returns the options passed to the generator" do
      expect(generator.options).to eq(options)
    end
  end

  describe ".script_base_path" do
    it "raises an error when not implemented" do
      expect { described_class.script_base_path }.to raise_error(RuntimeError, /must define a script_base_path/)
    end
  end

  describe ".get_script" do
    # Create a temporary subclass for testing
    let(:test_generator_class) do
      Class.new(described_class) do
        def self.script_base_path
          File.join(File.dirname(__FILE__), "test_scripts")
        end
      end
    end

    context "with .erb template" do
      before do
        # Create a temporary directory and script file
        @temp_dir = Dir.mktmpdir
        @script_path = File.join(@temp_dir, "test_script.sh.erb")
        File.write(@script_path, "#!/bin/bash\nproject=<%= project_name %>\nurl=<%= base_url %>\n")

        # Override script_base_path to return our temp directory
        allow(test_generator_class).to receive(:script_base_path).and_return(@temp_dir)
      end

      after do
        FileUtils.rm_rf(@temp_dir) if @temp_dir
      end

      it "renders the ERB template with context" do
        context = { project_name: "chef", base_url: "https://omnitruck.chef.io" }
        script = test_generator_class.get_script("test_script.sh", context)

        expect(script).to include("project=chef")
        expect(script).to include("url=https://omnitruck.chef.io")
      end

      it "uses default values for missing context" do
        script = test_generator_class.get_script("test_script.sh", {})

        expect(script).to include("project=Chef")
        expect(script).to include("url=https://omnitruck.chef.io")
      end

      it "sets base_url to commercial API when license_id is provided" do
        context = { license_id: "test-commercial-key" }
        script = test_generator_class.get_script("test_script.sh", context)

        expect(script).to include("url=https://chefdownload-commercial.chef.io")
      end

      it "sets base_url to trial API when free- license_id is provided" do
        context = { license_id: "free-trial-123" }
        script = test_generator_class.get_script("test_script.sh", context)

        expect(script).to include("url=https://chefdownload-trial.chef.io")
      end

      it "sets base_url to trial API when trial- license_id is provided" do
        context = { license_id: "trial-xyz-456" }
        script = test_generator_class.get_script("test_script.sh", context)

        expect(script).to include("url=https://chefdownload-trial.chef.io")
      end
    end

    context "without .erb template" do
      before do
        @temp_dir = Dir.mktmpdir
        @script_path = File.join(@temp_dir, "plain_script.sh")
        File.write(@script_path, "#!/bin/bash\necho 'Hello World'\n")

        allow(test_generator_class).to receive(:script_base_path).and_return(@temp_dir)
      end

      after do
        FileUtils.rm_rf(@temp_dir) if @temp_dir
      end

      it "returns the script content as-is" do
        script = test_generator_class.get_script("plain_script.sh")

        expect(script).to eq("#!/bin/bash\necho 'Hello World'\n")
      end
    end

    context "with user_agent_headers" do
      before do
        @temp_dir = Dir.mktmpdir
        @script_path = File.join(@temp_dir, "ua_script.sh.erb")
        File.write(@script_path, "user_agent=<%= user_agent_string %>")

        allow(test_generator_class).to receive(:script_base_path).and_return(@temp_dir)
      end

      after do
        FileUtils.rm_rf(@temp_dir) if @temp_dir
      end

      it "generates user agent string from headers" do
        context = { user_agent_headers: { "X-Custom": "test" } }
        script = test_generator_class.get_script("ua_script.sh", context)

        expect(script).to include("user_agent=")
      end
    end

    context "with windows directory context" do
      before do
        @temp_dir = Dir.mktmpdir
        @script_path = File.join(@temp_dir, "windows_dir.sh.erb")
        File.write(@script_path, "dir=<%= windows_dir %>")

        allow(test_generator_class).to receive(:script_base_path).and_return(@temp_dir)
      end

      after do
        FileUtils.rm_rf(@temp_dir) if @temp_dir
      end

      it "uses omnibus directory for chef" do
        context = { default_product: "chef" }
        script = test_generator_class.get_script("windows_dir.sh", context)

        expect(script).to include("dir=opscode")
      end
    end
  end

  describe "#get_script" do
    # Create a concrete implementation for testing instance method
    let(:test_generator_class) do
      Class.new(described_class) do
        def self.script_base_path
          File.join(File.dirname(__FILE__), "test_scripts")
        end
      end
    end

    let(:test_generator) { test_generator_class.new(options) }

    before do
      @temp_dir = Dir.mktmpdir
      @script_path = File.join(@temp_dir, "instance_script.sh.erb")
      File.write(@script_path, "#!/bin/bash\nproject=<%= project_name %>\n")

      allow(test_generator_class).to receive(:script_base_path).and_return(@temp_dir)
    end

    after do
      FileUtils.rm_rf(@temp_dir) if @temp_dir
    end

    it "calls the class method get_script" do
      script = test_generator.get_script("instance_script.sh", { project_name: "test" })

      expect(script).to include("project=test")
    end
  end

  describe "default context values" do
    let(:test_generator_class) do
      Class.new(described_class) do
        def self.script_base_path
          File.join(File.dirname(__FILE__), "test_scripts")
        end
      end
    end

    before do
      @temp_dir = Dir.mktmpdir
      @script_path = File.join(@temp_dir, "defaults.sh.erb")
      File.write(@script_path, <<~SCRIPT)
        project=<%= project_name %>
        url=<%= base_url %>
        product=<%= default_product %>
        bug=<%= bug_url %>
        support=<%= support_url %>
        resources=<%= resources_url %>
        macos=<%= macos_dir %>
        windows=<%= windows_dir %>
      SCRIPT

      allow(test_generator_class).to receive(:script_base_path).and_return(@temp_dir)
    end

    after do
      FileUtils.rm_rf(@temp_dir) if @temp_dir
    end

    it "provides all default context values" do
      script = test_generator_class.get_script("defaults.sh", {})

      expect(script).to include("project=Chef")
      expect(script).to include("url=https://omnitruck.chef.io")
      expect(script).to include("product=chef")
      expect(script).to include("bug=https://github.com/chef/omnitruck/issues/new")
      expect(script).to include("support=https://www.chef.io/support/tickets")
      expect(script).to include("resources=https://www.chef.io/support")
      expect(script).to include("macos=chef_software")
      expect(script).to include("windows=opscode")
    end
  end
end
