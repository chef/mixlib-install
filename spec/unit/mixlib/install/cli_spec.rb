require "spec_helper"
require "tmpdir"
require "mixlib/install/cli"

# In-process CLI specs. spec/functional covers the real executable against
# the real services; these pin down option handling without the network.
RSpec.describe Mixlib::Install::Cli do
  def cli(*args)
    described_class.start(args)
  end

  around do |example|
    with_modified_env("CHEF_LICENSE_KEY" => nil) { example.run }
  end

  describe "version" do
    it "prints the gem version" do
      expect { cli("version") }.to output("#{Mixlib::Install::VERSION}\n").to_stdout
    end
  end

  describe "list-products" do
    it "prints one product key per line" do
      expect { cli("list-products") }.to output(/^chef$\n.*^inspec$/m).to_stdout
    end
  end

  describe "list-versions" do
    it "prints the versions one per line" do
      allow(Mixlib::Install).to receive(:available_versions).with("chef", "stable", license_id: nil).and_return(%w{17.0.0 18.0.0})

      expect { cli("list-versions", "chef", "stable") }.to output("17.0.0\n18.0.0\n").to_stdout
    end

    it "passes -L through as the license id" do
      expect(Mixlib::Install).to receive(:available_versions).with("chef", "stable", license_id: "free-1").and_return([])

      expect { cli("list-versions", "chef", "stable", "-L", "free-1") }.to output.to_stdout
    end

    it "falls back to CHEF_LICENSE_KEY" do
      expect(Mixlib::Install).to receive(:available_versions).with("chef", "stable", license_id: "free-env").and_return([])

      with_modified_env("CHEF_LICENSE_KEY" => "free-env") do
        expect { cli("list-versions", "chef", "stable") }.to output.to_stdout
      end
    end

    it "prefers -L over CHEF_LICENSE_KEY" do
      expect(Mixlib::Install).to receive(:available_versions).with("chef", "stable", license_id: "free-flag").and_return([])

      with_modified_env("CHEF_LICENSE_KEY" => "free-env") do
        expect { cli("list-versions", "chef", "stable", "-L", "free-flag") }.to output.to_stdout
      end
    end
  end

  describe "download" do
    let(:artifact) do
      Mixlib::Install::ArtifactInfo.new(
        url: "https://packages.example.com/chef_18.0.0-1_amd64.deb",
        version: "18.0.0",
        platform: "ubuntu",
        platform_version: "22.04",
        architecture: "x86_64"
      )
    end
    let(:installer) { instance_double(Mixlib::Install, artifact_info: artifact) }
    let(:platform_args) { %w{-p ubuntu -l 22.04} }

    before { allow(Mixlib::Install).to receive(:new).and_return(installer) }

    it "builds installer options from the flags" do
      expect { cli("download", "chef", "-c", "current", "-v", "18.0.0", "-a", "aarch64", *platform_args, "--url") }.to output.to_stdout

      expect(Mixlib::Install).to have_received(:new).with(
        channel: :current,
        product_name: "chef",
        product_version: "18.0.0",
        platform_version_compatibility_mode: true,
        architecture: "aarch64",
        platform: "ubuntu",
        platform_version: "22.04",
        license_id: nil
      )
    end

    it "defaults to the stable channel, the latest version and x86_64" do
      expect { cli("download", "chef", *platform_args, "--url") }.to output.to_stdout

      expect(Mixlib::Install).to have_received(:new)
        .with(hash_including(channel: :stable, product_version: :latest, architecture: "x86_64"))
    end

    it "detects the platform when none is given" do
      allow(Mixlib::Install).to receive(:detect_platform)
        .and_return(platform: "el", platform_version: "9", architecture: "aarch64")

      expect { cli("download", "chef", "--url") }.to output.to_stdout

      expect(Mixlib::Install).to have_received(:new)
        .with(hash_including(platform: "el", platform_version: "9", architecture: "aarch64"))
    end

    it "takes the license id from CHEF_LICENSE_KEY" do
      with_modified_env("CHEF_LICENSE_KEY" => "free-env") do
        expect { cli("download", "chef", *platform_args, "--url") }.to output.to_stdout
      end

      expect(Mixlib::Install).to have_received(:new).with(hash_including(license_id: "free-env"))
    end

    it "prints only the URL with --url" do
      expect(installer).not_to receive(:download_artifact)

      expect { cli("download", "chef", *platform_args, "--url") }.to output("#{artifact.url}\n").to_stdout
    end

    it "downloads to the requested directory" do
      Dir.mktmpdir do |dir|
        expect(installer).to receive(:download_artifact).with(dir).and_return(File.join(dir, "chef.deb"))

        expect { cli("download", "chef", *platform_args, "-d", dir) }
          .to output(/Starting download #{Regexp.escape(artifact.url)}\nDownload saved to #{Regexp.escape(dir)}/).to_stdout
      end
    end

    it "prints the artifact attributes as JSON with --attributes" do
      expect { cli("download", "chef", *platform_args, "--url", "--attributes") }
        .to output(/"version": "18.0.0"/).to_stdout
    end

    it "exits with the lookup error when no artifact matches" do
      allow(installer).to receive(:artifact_info)
        .and_raise(Mixlib::Install::Backend::ArtifactsNotFound, "No artifacts found matching criteria.")

      expect { cli("download", "chef", *platform_args, "--url") }
        .to raise_error(SystemExit) { |e| expect(e.status).to eq(1) }
        .and output(/No artifacts found matching criteria/).to_stderr
    end

    it "rejects an unsupported channel" do
      expect { cli("download", "chef", "-c", "nightly", *platform_args) }
        .to raise_error(SystemExit)
        .and output(/Expected '--channel' to be one of/).to_stderr
      expect(Mixlib::Install).not_to have_received(:new)
    end
  end

  describe "install-script" do
    it "prints a Bourne script by default" do
      expect { cli("install-script") }.to output(/\A#!\/bin\/sh/).to_stdout
    end

    it "writes a PowerShell script to a file" do
      Dir.mktmpdir do |dir|
        file = File.join(dir, "install.ps1")

        expect { cli("install-script", "-t", "ps1", "-o", file) }.to output("Script written to #{file}\n").to_stdout
        expect(File.read(file)).to include("function Install-Project")
      end
    end

    it "points the script at an alternate endpoint" do
      expect { cli("install-script", "--endpoint", "https://omnitruck.example.com") }
        .to output(%r{https://omnitruck\.example\.com}).to_stdout
    end

    it "rejects an unknown script type" do
      expect { cli("install-script", "-t", "zsh") }
        .to raise_error(SystemExit)
        .and output(/Expected '--type' to be one of/).to_stderr
    end
  end
end
