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
require "mixlib/install"
require "mixlib/install/version"

context "Mixlib::Install::Generator", :vcr do
  let(:channel) { nil }
  let(:product_version) { "latest" }
  let(:add_options) { {} }

  let(:options) do
    {
      product_name: "chef",
      channel: channel,
      product_version: product_version,
    }
  end

  let(:install_script) do
    options.merge!(add_options)
    Mixlib::Install.new(options).install_command
  end

  shared_examples_for "the correct sh script" do
    it "generates an sh script" do
      expect(install_script).to be_a(String)
      expect(install_script).to start_with("#!/bin/sh")
      expect(install_script).to include('install_file $filetype "$download_filename"')
    end
    it "sets http proxy environment variables" do
      expect(install_script).to match(/^\s*HTTPS_PROXY=\S+/)
    end
    it "exports proxy environment variables" do
      expect(install_script).to match(/^\s*export\s+HTTPS_PROXY$/)
    end
    it "does not export and set proxy environment variables using a single line" do
      expect(install_script).not_to match(/^\s*export\s+\S+=\S+/)
    end
  end

  context "for :unstable channel" do
    let(:channel) { :unstable }
    let(:product_version) { "12.5.1+20151210002019" }

    context "default shell type" do
      it_behaves_like "the correct sh script"
    end
  end

  context "for :stable channel" do
    let(:channel) { :stable }

    context "default shell type" do
      it_behaves_like "the correct sh script"
    end

    context "sh shell type" do
      let(:add_options) do
        {
          shell_type: :sh,
        }
      end

      it_behaves_like "the correct sh script"

      it "uses traditional text parsing for omnitruck without license_id" do
        expect(install_script).to include("awk '$1 == \"url\" { print $2 }'")
        expect(install_script).to include("grep '^url' $metadata_filename")
      end
    end

    context "with license_id" do
      let(:add_options) do
        {
          license_id: "test-license-key-123",
        }
      end

      it "includes license_id in the script variables" do
        expect(install_script).to include("license_id=test-license-key-123")
      end

      it "uses commercial API in metadata fetch" do
        expect(install_script).to include("https://chefdownload-commercial.chef.io")
      end

      it "includes JSON parsing logic for commercial API" do
        expect(install_script).to include("sed -n 's/.*\"url\":\"\\([^\"]*\\)\".*/\\1/p'")
        expect(install_script).to include("sed -n 's/.*\"sha256\":\"\\([^\"]*\\)\".*/\\1/p'")
      end

      it "checks for JSON format when license_id is present" do
        expect(install_script).to include("grep -q '^{' \"$metadata_filename\"")
      end

      it "sets use_content_disposition flag when license_id is present" do
        expect(install_script).to include("use_content_disposition=\"true\"")
      end

      it "includes content-disposition handling in wget" do
        expect(install_script).to include("--content-disposition")
      end

      it "includes content-disposition handling in curl" do
        expect(install_script).to include("-O -J")
      end

      it "skips caching checks when using content-disposition" do
        expect(install_script).to include('if [ "$use_content_disposition" = "true" ]; then')
        expect(install_script).to include('cached_file_available="false"')
      end

      it "downloads to temp file and extracts filename from headers" do
        expect(install_script).to include('temp_download="$download_dir/chef-download-temp.$$"')
        expect(install_script).to include("grep -i 'content-disposition'")
        expect(install_script).to include("mv \"$temp_download\" \"$download_filename\"")
      end

      it "extracts filetype from actual downloaded filename" do
        expect(install_script).to include("filetype=`echo $actual_filename | sed -e 's/^.*\\.//'`")
      end
    end

    context "with free- license_id" do
      let(:add_options) do
        {
          license_id: "free-trial-abc-123",
        }
      end

      it "includes license_id in the script variables" do
        expect(install_script).to include("license_id=free-trial-abc-123")
      end

      it "uses trial API in metadata fetch" do
        expect(install_script).to include("https://chefdownload-trial.chef.io")
      end

      it "includes JSON parsing logic for trial API" do
        expect(install_script).to include("sed -n 's/.*\"url\":\"\\([^\"]*\\)\".*/\\1/p'")
        expect(install_script).to include("sed -n 's/.*\"sha256\":\"\\([^\"]*\\)\".*/\\1/p'")
      end

      it "sets use_content_disposition flag for trial API" do
        expect(install_script).to include("use_content_disposition=\"true\"")
      end

      it "skips caching checks when using content-disposition" do
        expect(install_script).to include('if [ "$use_content_disposition" = "true" ]; then')
        expect(install_script).to include('cached_file_available="false"')
      end
    end

    context "with trial- license_id" do
      let(:add_options) do
        {
          license_id: "trial-xyz-456",
        }
      end

      it "includes license_id in the script variables" do
        expect(install_script).to include("license_id=trial-xyz-456")
      end

      it "uses trial API in metadata fetch" do
        expect(install_script).to include("https://chefdownload-trial.chef.io")
      end

      it "includes JSON parsing logic for trial API" do
        expect(install_script).to include("sed -n 's/.*\"url\":\"\\([^\"]*\\)\".*/\\1/p'")
        expect(install_script).to include("sed -n 's/.*\"sha256\":\"\\([^\"]*\\)\".*/\\1/p'")
      end

      it "sets use_content_disposition flag for trial API" do
        expect(install_script).to include("use_content_disposition=\"true\"")
      end

      it "skips caching checks when using content-disposition" do
        expect(install_script).to include('if [ "$use_content_disposition" = "true" ]; then')
        expect(install_script).to include('cached_file_available="false"')
      end

      it "downloads to temp file and extracts filename from headers" do
        expect(install_script).to include('temp_download="$download_dir/chef-download-temp.$$"')
        expect(install_script).to include("grep -i 'content-disposition'")
        expect(install_script).to include("mv \"$temp_download\" \"$download_filename\"")
      end

      it "includes multiple filename extraction methods" do
        # Method 1: Content-Disposition header
        expect(install_script).to include("grep -i 'content-disposition'")
        expect(install_script).to include("sed -n 's/.*filename=\"\\([^\"]*\\)\".*/\\1/p'")

        # Method 2: Location redirect header
        expect(install_script).to include("grep -i '^location:'")
        expect(install_script).to include("sed 's/.*\\///'")
        expect(install_script).to include("sed 's/?.*//'")

        # Method 3: URL pattern matching
        expect(install_script).to include("grep -i '\\.rpm\\|\\.deb\\|\\.pkg\\|\\.msi\\|\\.dmg'")
      end

      it "includes fallback filename construction" do
        expect(install_script).to include('echo "Warning: Could not extract filename from response headers, using fallback"')
        expect(install_script).to include('actual_filename="chef-${version}-1.${platform}${platform_version}.${machine}.rpm"')
        expect(install_script).to include('actual_filename="chef_${version}-1_${machine}.deb"')
        expect(install_script).to include('actual_filename="chef-${version}.dmg"')
        expect(install_script).to include('actual_filename="chef-${version}.pkg"')
      end

      it "extracts filetype from actual downloaded filename" do
        expect(install_script).to include("filetype=`echo $actual_filename | sed -e 's/^.*\\.//'`")
      end
    end

    context "with base_url" do
      let(:add_options) do
        {
          base_url: "https://custom.chef.io",
        }
      end

      it "includes base_url in the script" do
        expect(install_script).to include("base_api_url=\"https://custom.chef.io\"")
      end

      it "uses custom base_url in metadata fetch" do
        expect(install_script).to include("https://custom.chef.io")
      end

      it "uses traditional text parsing without license_id" do
        expect(install_script).to include("awk '$1 == \"url\" { print $2 }'")
        expect(install_script).to include("grep '^url' $metadata_filename")
      end
    end

    context "with base_url and license_id" do
      let(:add_options) do
        {
          base_url: "https://custom.chef.io",
          license_id: "test-license-123",
        }
      end

      it "includes both base_url and license_id in the script" do
        expect(install_script).to include("base_api_url=\"https://custom.chef.io\"")
        expect(install_script).to include("license_id=test-license-123")
      end

      it "uses custom base_url even with license_id" do
        expect(install_script).to include("https://custom.chef.io")
        # The script should set base_api_url to the custom URL in the conditional block
        expect(install_script).to match(/if \[ -z "\$base_api_url" \]; then\s+base_api_url="https:\/\/custom\.chef\.io"/m)
        # Verify the script includes the base_api_url variable assignment with custom URL
        expect(install_script).to include('base_api_url="https://custom.chef.io"')
      end

      it "includes JSON parsing logic for commercial API" do
        expect(install_script).to include("sed -n 's/.*\"url\":\"\\([^\"]*\\)\".*/\\1/p'")
        expect(install_script).to include("sed -n 's/.*\"sha256\":\"\\([^\"]*\\)\".*/\\1/p'")
      end
    end

    context "filename extraction for content-disposition" do
      let(:add_options) do
        {
          license_id: "test-license-key-123",
        }
      end

      it "includes all three extraction methods in order" do
        # Verify the extraction logic is ordered correctly
        script_lines = install_script.split("\n")

        # Find the indices of each method
        content_disposition_idx = script_lines.index { |l| l.include?("grep -i 'content-disposition'") && l.include?("sed -n") }
        location_idx = script_lines.index { |l| l.include?("grep -i '^location:'") && l.include?("sed") }
        fallback_idx = script_lines.index { |l| l.include?("Warning: Could not extract filename from response headers") }

        # Verify they exist and are in the correct order
        expect(content_disposition_idx).not_to be_nil
        expect(location_idx).not_to be_nil
        expect(fallback_idx).not_to be_nil
        expect(content_disposition_idx).to be < location_idx
        expect(location_idx).to be < fallback_idx
      end
    end

    context "chef-ice with commercial API" do
      let(:add_options) do
        {
          license_id: "test-license-key-123",
        }
      end

      it "includes package manager detection function" do
        expect(install_script).to include("determine_package_manager()")
      end

      it "includes platform normalization function" do
        expect(install_script).to include("normalize_platform_name()")
      end

      it "includes chef-ice conditional logic" do
        expect(install_script).to include('if [ "$project" = "chef-ice" ]; then')
      end

      it "includes RPM-based platform detection" do
        expect(install_script).to include("el|centos|rhel|fedora|amazon|rocky")
        expect(install_script).to include('echo "rpm"')
      end

      it "includes DEB-based platform detection" do
        expect(install_script).to include("debian|ubuntu|linuxmint|raspbian")
        expect(install_script).to include('echo "deb"')
      end

      it "includes TAR-based platform detection" do
        expect(install_script).to include("mac_os_x|macos|solaris*|smartos|freebsd|aix")
        expect(install_script).to include('echo "tar"')
      end

      it "includes platform normalization for Linux" do
        expect(install_script).to include("el|centos|rhel|fedora|rocky")
        expect(install_script).to include('echo "linux"')
      end

      it "includes platform normalization for macOS" do
        expect(install_script).to include("mac_os_x|macos")
        expect(install_script).to include('echo "macos"')
      end

      it "constructs chef-ice metadata URL with m, p, pm parameters" do
        expect(install_script).to include('metadata_url="$base_api_url/$channel/$project/metadata?license_id=$license_id&v=$version&m=$machine&p=$platform_param&pm=$package_manager"')
      end

      it "uses commercial API endpoint" do
        expect(install_script).to include("https://chefdownload-commercial.chef.io")
      end
    end

    context "chef-ice with trial API" do
      let(:add_options) do
        {
          license_id: "free-trial-xyz-123",
        }
      end

      it "includes chef-ice conditional logic" do
        expect(install_script).to include('if [ "$project" = "chef-ice" ]; then')
      end

      it "constructs chef-ice metadata URL with m, p, pm parameters" do
        expect(install_script).to include('metadata_url="$base_api_url/$channel/$project/metadata?license_id=$license_id&v=$version&m=$machine&p=$platform_param&pm=$package_manager"')
      end

      it "uses trial API endpoint" do
        expect(install_script).to include("https://chefdownload-trial.chef.io")
      end

      it "works with trial- prefix" do
        add_options[:license_id] = "trial-abc-456"
        expect(install_script).to include("https://chefdownload-trial.chef.io")
        expect(install_script).to include('if [ "$project" = "chef-ice" ]; then')
      end
    end

    context "for windows" do
      shared_examples_for "the correct ps1 script" do
        it "generates a ps1 script" do
          expect(install_script).to be_a(String)
          expect(install_script).to start_with("new-module -name Installer-Module -scriptblock")
          expect(install_script).to include("set-alias install -value Install-Project")
        end
      end

      context "when platform is set" do
        let(:add_options) do
          {
            platform: "windows",
            platform_version: "2012r2",
            architecture: "x86_64",
          }
        end

        it_behaves_like "the correct ps1 script"

        it "adds an architecture param" do
          expect(install_script).to match(/Install-Project -project #{options[:product_name]} -version .* -channel #{options[:channel]} -architecture #{options[:architecture]}\n/)
        end

      end

      context "when shell_type is set" do
        let(:add_options) do
          {
            shell_type: :ps1,
          }
        end

        it_behaves_like "the correct ps1 script"

        it "adds omits the architecture param" do
          expect(install_script).to match(/Install-Project -project #{options[:product_name]} -version .* -channel #{options[:channel]}\n/)
        end

        it "uses traditional text parsing for omnitruck without license_id" do
          expect(install_script).to include("-split '\\n'")
          expect(install_script).to include("$key, $value = $_ -split '\\s+'")
        end
      end

      context "with license_id for PowerShell" do
        let(:add_options) do
          {
            shell_type: :ps1,
            license_id: "test-license-key-456",
          }
        end

        it_behaves_like "the correct ps1 script"

        it "includes license_id in install command" do
          expect(install_script).to match(/Install-Project -project #{options[:product_name]} -version .* -channel #{options[:channel]} -license_id test-license-key-456\n/)
        end

        it "includes license_id parameter in Get-ProjectMetadata function" do
          expect(install_script).to include("[string]")
          expect(install_script).to include("$license_id")
        end

        it "uses commercial API in metadata fetch" do
          expect(install_script).to include("https://chefdownload-commercial.chef.io")
        end

        it "includes JSON parsing logic for commercial API" do
          expect(install_script).to include("ConvertFrom-Json")
          expect(install_script).to include("$json.url")
          expect(install_script).to include("$json.sha256")
        end

        it "includes conditional parsing based on license_id" do
          expect(install_script).to include("if ($license_id)")
        end
      end

      context "with free- license_id for PowerShell" do
        let(:add_options) do
          {
            shell_type: :ps1,
            license_id: "free-trial-789",
          }
        end

        it_behaves_like "the correct ps1 script"

        it "includes license_id in install command" do
          expect(install_script).to match(/Install-Project -project #{options[:product_name]} -version .* -channel #{options[:channel]} -license_id free-trial-789\n/)
        end

        it "uses trial API in metadata fetch" do
          expect(install_script).to include("https://chefdownload-trial.chef.io")
        end

        it "includes JSON parsing logic for trial API" do
          expect(install_script).to include("ConvertFrom-Json")
          expect(install_script).to include("$json.url")
          expect(install_script).to include("$json.sha256")
        end
      end

      context "with trial- license_id for PowerShell" do
        let(:add_options) do
          {
            shell_type: :ps1,
            license_id: "trial-abc-xyz",
          }
        end

        it_behaves_like "the correct ps1 script"

        it "includes license_id in install command" do
          expect(install_script).to match(/Install-Project -project #{options[:product_name]} -version .* -channel #{options[:channel]} -license_id trial-abc-xyz\n/)
        end

        it "uses trial API in metadata fetch" do
          expect(install_script).to include("https://chefdownload-trial.chef.io")
        end

        it "includes JSON parsing logic for trial API" do
          expect(install_script).to include("ConvertFrom-Json")
          expect(install_script).to include("$json.url")
          expect(install_script).to include("$json.sha256")
        end
      end

      context "with base_url for PowerShell" do
        let(:add_options) do
          {
            shell_type: :ps1,
            base_url: "https://custom.chef.io",
          }
        end

        it_behaves_like "the correct ps1 script"

        it "includes base_url in the script" do
          expect(install_script).to include('$base_server_uri = "https://custom.chef.io"')
        end

        it "uses custom base_url in metadata fetch" do
          expect(install_script).to include("https://custom.chef.io")
        end

        it "uses traditional text parsing without license_id" do
          expect(install_script).to include("-split '\\n'")
          expect(install_script).to include("$key, $value = $_ -split '\\s+'")
        end
      end

      context "with base_url and license_id for PowerShell" do
        let(:add_options) do
          {
            shell_type: :ps1,
            base_url: "https://custom.chef.io",
            license_id: "test-license-123",
          }
        end

        it_behaves_like "the correct ps1 script"

        it "includes both base_url and license_id in the script" do
          expect(install_script).to include('$base_server_uri = "https://custom.chef.io"')
          expect(install_script).to include("test-license-123")
        end

        it "uses custom base_url even with license_id" do
          expect(install_script).to include("https://custom.chef.io")
          # Script should conditionally assign base_server_uri, not hardcode commercial endpoint
          expect(install_script).to match(/\$base_server_uri\s*=.*if.*else/m)
        end

        it "includes JSON parsing logic for commercial API" do
          expect(install_script).to include("ConvertFrom-Json")
          expect(install_script).to include("$json.url")
          expect(install_script).to include("$json.sha256")
        end
      end

      context "chef-ice with commercial API for PowerShell" do
        let(:add_options) do
          {
            product_name: "chef-ice",
            shell_type: :ps1,
            license_id: "test-license-key-123",
          }
        end

        it_behaves_like "the correct ps1 script"

        it "includes chef-ice conditional logic" do
          expect(install_script).to include('if ($project -eq "chef-ice")')
        end

        it "includes simplified parameters for chef-ice on Windows" do
          expect(install_script).to include('$platform_param = "windows"')
          expect(install_script).to include('$package_manager = "msi"')
        end

        it "constructs chef-ice metadata URL with m, p, pm parameters" do
          expect(install_script).to include('$metadata_url = "$base_server_uri$channel/$project/metadata?license_id=$license_id&v=$version&m=$architecture&p=$platform_param&pm=$package_manager"')
        end

        it "uses commercial API endpoint" do
          expect(install_script).to include("https://chefdownload-commercial.chef.io")
        end
      end

      context "chef-ice with trial API for PowerShell" do
        let(:add_options) do
          {
            product_name: "chef-ice",
            shell_type: :ps1,
            license_id: "free-trial-xyz-123",
          }
        end

        it_behaves_like "the correct ps1 script"

        it "includes chef-ice conditional logic" do
          expect(install_script).to include('if ($project -eq "chef-ice")')
        end

        it "includes simplified parameters for chef-ice on Windows" do
          expect(install_script).to include('$platform_param = "windows"')
          expect(install_script).to include('$package_manager = "msi"')
        end

        it "uses trial API endpoint" do
          expect(install_script).to include("https://chefdownload-trial.chef.io")
        end

        it "works with trial- prefix" do
          add_options[:license_id] = "trial-abc-456"
          expect(install_script).to include("https://chefdownload-trial.chef.io")
        end
      end
    end
  end

  context "for user agent headers" do
    let(:context) { {} }

    context "when using class method" do
      let(:install_script) { Mixlib::Install.install_sh(context) }

      context "without user_agent_headers" do
        it "sets the default agent header" do
          expect(install_script).to match(/"User-Agent: mixlib-install\/#{Mixlib::Install::VERSION}"/)
        end
      end

      context "when it excludes mixlib-install agent header" do
        let(:context) do
          { user_agent_headers: %w{testheader/1.2.3} }
        end

        it "sets adds the default headers" do
          expect(install_script).to match(/"User-Agent: mixlib-install\/#{Mixlib::Install::VERSION} testheader\/1.2.3"/)
        end
      end

      context "when it includes mixlib-install agent header" do
        let(:context) do
          { user_agent_headers: %W{mixlib-install/#{Mixlib::Install::VERSION} testheader/4.5.6} }
        end

        it "doesn't duplicate the default header" do
          expect(install_script).to match(/"User-Agent: mixlib-install\/#{Mixlib::Install::VERSION} testheader\/4.5.6"/)
        end
      end
    end

    context "when using instance method" do
      let(:channel) { :stable }

      context "without user_agent_headers set" do
        it "sets the default agent header" do
          expect(install_script).to match(/"User-Agent: mixlib-install\/#{Mixlib::Install::VERSION}"/)
        end
      end

      context "with user_agent_headers set" do
        let(:add_options) do
          { user_agent_headers: ["testheader/11.22.33"] }
        end

        it "sets adds the additional headers" do
          expect(install_script).to match(/"User-Agent: mixlib-install\/#{Mixlib::Install::VERSION} testheader\/11.22.33"/)
        end
      end
    end
  end

  context "when setting install_command_options" do
    let(:channel) { :stable }

    context "for powershell install params" do
      let(:install_command_options) do
        {
          http_proxy: "http://sam:iam@greeneggsandham:1111",
          download_url_override: "https://packages.chef.io/files/stable/chef/12.19.36/windows/2012/chef-client-12.19.36-1-x64.msi",
          checksum: "1baed41a777d298a08fc0a34dd1eaaa76143bde222fd22c31aa709c7911dec48",
          install_strategy: "once",
        }
      end

      let(:add_options) do
        {
          install_command_options: install_command_options,
          shell_type: :ps1,
        }
      end

      it "#install_command adds http_proxy param" do
        expect(install_script).to match(/http_proxy '#{install_command_options[:http_proxy]}'/)
      end

      it "adds download_url_override var" do
        expect(install_script).to match(/download_url_override '#{install_command_options[:download_url_override]}'/)
      end

      it "adds checksum var" do
        expect(install_script).to match(/checksum '#{install_command_options[:checksum]}'/)
      end

      it "adds install_strategy var" do
        expect(install_script).to match(/install_strategy '#{install_command_options[:install_strategy]}'/)
      end
    end

    context "for bourne install params" do
      let(:install_command_options) do
        {
          cmdline_dl_dir: "/hereiam",
          download_url_override: "https://packages.chef.ioo/files/stable/chef/12.19.36/debian/8/chef_12.19.36-1_amd64.deb",
          checksum: "292651ac21e093a40446da6b9a9b075ad31be6991a6f7ab63d5b6c2edabaa03c",
          install_strategy: "once",
        }
      end

      let(:add_options) do
        {
          install_command_options: install_command_options,
        }
      end

      it "adds cmdline_dl_dir var" do
        expect(install_script).to match(/cmdline_dl_dir='#{install_command_options[:cmdline_dl_dir]}'/)
      end

      it "adds download_url_override var" do
        expect(install_script).to match(/download_url_override='#{install_command_options[:download_url_override]}'/)
      end

      it "adds checksum var" do
        expect(install_script).to match(/checksum='#{install_command_options[:checksum]}'/)
      end

      it "adds install_strategy var" do
        expect(install_script).to match(/install_strategy='#{install_command_options[:install_strategy]}'/)
      end
    end

    context "for bourne install params without checksum" do
      let(:install_command_options) do
        {
          download_url_override: "https://packages.chef.io/files/stable/chef/12.19.36/debian/8/chef_12.19.36-1_amd64.deb",
        }
      end

      let(:add_options) do
        {
          install_command_options: install_command_options,
        }
      end

      it "skips checksum verification when sha256 is empty" do
        expect(install_script).to include("Skipping checksum verification - no checksum provided")
      end

      it "includes checksum verification check" do
        expect(install_script).to match(/if \[ -z "\$sha256" \]; then/)
      end
    end
  end
end
