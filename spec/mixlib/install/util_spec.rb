require "spec_helper"

describe Mixlib::Install::Util do
  describe ".pretty_version" do
    it "describes the effect of 'true'" do
      expect(Mixlib::Install::Util.pretty_version("true")).to eql("install only if missing")
    end

    it "describes the effect of 'latest'" do
      expect(Mixlib::Install::Util.pretty_version("latest")).to eql("always install latest version")
    end

    it "returns the same string normally" do
      expect(Mixlib::Install::Util.pretty_version("1.2.0")).to eql("1.2.0")
    end
  end

  describe ".wrap_command" do
    it "wraps false when passed nil" do
      expect(Mixlib::Install::Util.wrap_command(nil)).to eql("sh -c '\nfalse\n'")
    end
    it "wraps true when passed an empty string" do
      expect(Mixlib::Install::Util.wrap_command("")).to eql("sh -c '\ntrue\n'")
    end
    it "wraps the command" do
      expect(Mixlib::Install::Util.wrap_command("echo \"yes\"")).to eql("sh -c '\necho \"yes\"\n'")
    end
  end

  describe ".shell_var" do
    it "behaves correctly on windows" do
      expect(Mixlib::Install::Util.shell_var("foo", "bar", true)).to eql('$foo = "bar"')
    end
    it "behaves correctly on unix" do
      expect(Mixlib::Install::Util.shell_var("foo", "bar")).to eql('foo="bar"')
    end
  end

  describe ".shell_env_var" do
    it "behaves correctly on windows" do
      expect(Mixlib::Install::Util.shell_env_var("foo", "bar", true)).to eql('$env:foo = "bar"')
    end
    it "behaves correctly on unix" do
      expect(Mixlib::Install::Util.shell_env_var("foo", "bar")).to eql('foo="bar"; export foo')
    end
  end

  describe ".shell_code_from_file" do
    describe "reads the correct file" do
      it "on windows" do
        expect(IO).to receive(:read).with("test_file.ps1")
        Mixlib::Install::Util.shell_code_from_file("", "test_file", true)
      end

      it "on unix" do
        expect(IO).to receive(:read).with("test_file.sh")
        Mixlib::Install::Util.shell_code_from_file("", "test_file", false)
      end
    end

    describe "wraps the correct data" do
      before do
        allow(IO).to receive(:read).with("test_file.sh").and_return("some test data")
      end

      it "with no variables" do
        expect(Mixlib::Install::Util).to receive(:wrap_shell).with("\n\nsome test data", false, {})
        Mixlib::Install::Util.shell_code_from_file("", "test_file", false)
      end

      it "with some variables" do
        expect(Mixlib::Install::Util).to receive(:wrap_shell).with("foo=bar\nwoo=hoo\n\nsome test data", false, {})
        Mixlib::Install::Util.shell_code_from_file("foo=bar\nwoo=hoo", "test_file", false)
      end
    end
  end

  describe ".wrap_shell" do
    describe "with no options" do
      it "on windows" do
        expect(Mixlib::Install::Util.wrap_shell("some shell code", true)).to eql("\nsome shell code")
      end
      it "on unix" do
        expect(Mixlib::Install::Util.wrap_shell("some shell code", false)).to eql("sh -c '\n\nsome shell code\n'")
      end
    end

    describe "with an http proxy" do
      let(:opts) { { http_proxy: "http://localhost:4321" } }
      it "on unix" do
        expect(Mixlib::Install::Util.wrap_shell("some shell code", false, opts)).to eql("sh -c '\nhttp_proxy=\"http://localhost:4321\"; export http_proxy\nHTTP_PROXY=\"http://localhost:4321\"; export HTTP_PROXY\nsome shell code\n'")
      end
    end

    describe "with an https proxy" do
      let(:opts) { { https_proxy: "https://localhost:4321" } }
      it "on unix" do
        expect(Mixlib::Install::Util.wrap_shell("some shell code", false, opts)).to eql("sh -c '\nhttps_proxy=\"https://localhost:4321\"; export https_proxy\nHTTPS_PROXY=\"https://localhost:4321\"; export HTTPS_PROXY\nsome shell code\n'")
      end
    end
  end
end
