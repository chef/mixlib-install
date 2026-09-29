require "spec_helper"
require "open3"
require "tmpdir"

# The generators assemble scripts from ERB fragments, so a stray quote or an
# unbalanced if/fi in any fragment or context combination only shows up when a
# shell parses the result. Parse every variant with each shell that is
# installed.
RSpec.describe "generated script syntax" do
  def self.available?(cmd)
    ENV["PATH"].to_s.split(File::PATH_SEPARATOR).any? do |dir|
      exe = File.join(dir, cmd)
      File.executable?(exe) || File.executable?("#{exe}.exe")
    end
  end

  POSIX_SHELLS = [%w{sh}, %w{bash}, %w{dash}, %w{ksh}, %w{busybox sh}].freeze

  sh_variants = {
    "install.sh" => -> { Mixlib::Install.install_sh },
    "install.sh with a license id" => -> { Mixlib::Install.install_sh(license_id: "free-abc-123") },
    "install.sh with a base url" => -> { Mixlib::Install.install_sh(base_url: "https://omnitruck.example.com") },
    "install.sh with custom user agents" => -> { Mixlib::Install.install_sh(user_agent_headers: %w{a/1 b/2}) },
    "install command for chef" => -> { Mixlib::Install.new(product_name: "chef", channel: :stable).install_command },
    "install command for chef-ice with a license" => lambda {
      Mixlib::Install.new(product_name: "chef-ice", channel: :stable, license_id: "free-abc-123").install_command
    },
    "install command with install_command_options" => lambda {
      Mixlib::Install.new(product_name: "chef", channel: :stable, product_version: "18.0.0",
                          install_command_options: { install_strategy: "once" }).install_command
    },
    "detect_platform_sh" => -> { Mixlib::Install.detect_platform_sh },
  }

  ps1_variants = {
    "install.ps1" => -> { Mixlib::Install.install_ps1 },
    "install.ps1 with a license id" => -> { Mixlib::Install.install_ps1(license_id: "free-abc-123") },
    "install.ps1 with a base url" => -> { Mixlib::Install.install_ps1(base_url: "https://omnitruck.example.com") },
    "install command for chef (ps1)" => lambda {
      Mixlib::Install.new(product_name: "chef", channel: :stable, shell_type: :ps1).install_command
    },
    "install command for chef-ice with a license (ps1)" => lambda {
      Mixlib::Install.new(product_name: "chef-ice", channel: :stable, shell_type: :ps1, license_id: "free-abc-123").install_command
    },
    "detect_platform_ps1" => -> { Mixlib::Install.detect_platform_ps1 },
  }

  around do |example|
    Dir.mktmpdir("script-syntax") do |dir|
      @dir = dir
      example.run
    end
  end

  def write(name, content)
    File.join(@dir, name).tap { |path| File.write(path, content) }
  end

  POSIX_SHELLS.each do |shell|
    context "parsed by #{shell.join(" ")}" do
      before do
        skip "POSIX shells are not available on Windows" if Gem.win_platform?
        skip "#{shell.first} is not installed" unless self.class.available?(shell.first)
      end

      sh_variants.each do |name, generate|
        it "accepts #{name}" do
          path = write("script.sh", instance_exec(&generate))
          out, status = Open3.capture2e(*shell, "-n", path)

          expect(status).to be_success, out
        end
      end
    end
  end

  context "parsed by PowerShell" do
    before { skip "pwsh is not installed" unless self.class.available?("pwsh") }

    ps1_variants.each do |name, generate|
      it "accepts #{name}" do
        path = write("script.ps1", instance_exec(&generate))
        parse = "$e = $null; [void][System.Management.Automation.Language.Parser]::ParseFile('#{path}', [ref]$null, [ref]$e); " \
                "$e | ForEach-Object { $_.ToString() }; exit $e.Count"
        out, status = Open3.capture2e("pwsh", "-NoProfile", "-NonInteractive", "-Command", parse)

        expect(status).to be_success, out
      end
    end
  end
end
