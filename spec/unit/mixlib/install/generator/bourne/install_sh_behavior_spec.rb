require "spec_helper"
require "open3"
require "tmpdir"
require "fileutils"

# Runs the generated install.sh end to end against FakeOmnitruck. This covers
# what string matching on the rendered template cannot: argument parsing, the
# metadata URL the script builds, downloader error handling, checksum
# verification and filename detection for licensed downloads.
RSpec.describe "generated install.sh", :shell do
  before(:all) do
    skip "install.sh needs a POSIX sh" if Gem.win_platform?
    @server = FakeOmnitruck.new.start
  end

  after(:all) { @server&.stop }

  let(:server) { @server }
  let(:workdir) { Dir.mktmpdir("install-sh-spec") }
  let(:marker) { File.join(workdir, "installed") }
  let(:script) { File.join(workdir, "install.sh") }
  let(:context) { {} }
  let(:extra_env) { {} }

  before do
    server.requests.clear
    server.metadata_status = 200
    server.package_headers = {}
    server.package_path_suffix = "/files/stable/chef/18.0.0/#{FakeOmnitruck::PACKAGE_NAME}"
    server.sha256_override = nil
    File.write(script, Mixlib::Install.install_sh(context))
  end

  after { FileUtils.rm_rf(workdir) }

  # Put a failing stub for the downloader we are *not* testing first on PATH,
  # so install.sh falls through to the one we are.
  def shim_dir_without(tool)
    dir = File.join(workdir, "shims")
    FileUtils.mkdir_p(dir)
    shim = File.join(dir, tool)
    File.write(shim, "#!/bin/sh\nexit 1\n")
    File.chmod(0o755, shim)
    dir
  end

  def curl_version
    Gem::Version.new(`curl --version`[/\Acurl (\d+(?:\.\d+)+)/, 1] || "0")
  end

  def run_install(*args)
    env = {
      "PATH" => "#{shim_dir_without(@other_downloader)}#{File::PATH_SEPARATOR}#{ENV["PATH"]}",
      "FAKE_INSTALL_MARKER" => marker,
      "CHEF_LICENSE_KEY" => nil,
      "CI" => "true",
      "TMPDIR" => workdir,
    }.merge(extra_env)
    out, status = Open3.capture2e(env, "sh", script, "-b", server.base_url, *args)
    [out, status]
  end

  { "curl" => "wget", "wget" => "curl" }.each do |downloader, other|
    context "downloading with #{downloader}" do
      before do
        skip "#{downloader} is not installed" unless system("command -v #{downloader} >/dev/null 2>&1")
        @other_downloader = other
      end

      it "installs from omnitruck metadata and verifies the checksum" do
        out, status = run_install("-v", "18.0.0")

        expect(status).to be_success, out
        expect(out).to include("trying #{downloader}...")
        expect(out).to include("Comparing checksum")
        expect(File.read(marker)).to eq("installed\n")
      end

      it "requests metadata for the requested project, channel, version and host platform" do
        run_install("-P", "chef", "-c", "current", "-v", "18.0.0")

        request = server.metadata_requests.last
        expect(request.path).to eq("/current/chef/metadata")
        expect(request.query).to include("v" => "18.0.0")
        expect(request.query.keys).to include("p", "pv", "m")
        expect(request.query).not_to have_key("license_id")
        expect(request.query).not_to have_key("pm")
      end

      it "sends the mixlib-install user agent" do
        run_install("-v", "18.0.0")

        expect(server.requests.first.headers["user-agent"].join).to include("mixlib-install/#{Mixlib::Install::VERSION}")
      end

      it "passes an explicit package manager through as pm" do
        run_install("-v", "18.0.0", "-i", "rpm")

        expect(server.metadata_requests.last.query).to include("pm" => "rpm")
      end

      it "refuses to install a package whose checksum does not match" do
        server.sha256_override = "0" * 64

        out, status = run_install("-v", "18.0.0")

        expect(status).not_to be_success
        expect(out).to match(/checksum/i)
        expect(File).not_to exist(marker)
      end

      it "fails without installing when no metadata is found" do
        server.metadata_status = 404

        _out, status = run_install("-v", "99.99.99")

        expect(status).not_to be_success
        expect(File).not_to exist(marker)
      end

      it "explains a 404 when no metadata is found" do
        if downloader == "curl" && curl_version < Gem::Version.new("7.88")
          pending "curl #{curl_version} writes no -D header dump with --fail, so do_curl cannot see the 404"
        end
        server.metadata_status = 404

        out, _status = run_install("-v", "99.99.99")

        expect(out).to include("ERROR 404")
      end

      context "with a license id" do
        before do
          server.package_headers = { "Content-Disposition" => "attachment; filename=\"#{FakeOmnitruck::PACKAGE_NAME}\"" }
        end

        it "adds the license id to the metadata request and names the file from Content-Disposition" do
          out, status = run_install("-v", "18.0.0", "-L", "free-abc-123")

          expect(status).to be_success, out
          expect(server.metadata_requests.last.query).to include("license_id" => "free-abc-123")
          expect(out).to include("Downloaded as: ")
          expect(out).to include(FakeOmnitruck::PACKAGE_NAME)
          expect(File.read(marker)).to eq("installed\n")
        end

        it "accepts an unquoted Content-Disposition filename" do
          server.package_headers = { "Content-Disposition" => "attachment; filename=#{FakeOmnitruck::PACKAGE_NAME}" }

          out, status = run_install("-v", "18.0.0", "-L", "free-abc-123")

          expect(status).to be_success, out
          expect(out).to include("Downloaded as: ")
          expect(out).to include(FakeOmnitruck::PACKAGE_NAME)
        end

        context "from CHEF_LICENSE_KEY" do
          let(:extra_env) { { "CHEF_LICENSE_KEY" => "free-from-env" } }

          it "uses the environment variable when -L is not given" do
            run_install("-v", "18.0.0")

            expect(server.metadata_requests.last.query).to include("license_id" => "free-from-env")
          end
        end
      end

      context "with the license id baked into the script" do
        let(:context) { { license_id: "free-baked-in" } }

        it "uses it without -L" do
          server.package_headers = { "Content-Disposition" => "attachment; filename=\"#{FakeOmnitruck::PACKAGE_NAME}\"" }

          out, status = run_install("-v", "18.0.0")

          expect(status).to be_success, out
          expect(server.metadata_requests.last.query).to include("license_id" => "free-baked-in")
        end
      end
    end
  end

  context "downloading with curl when a response header merely contains 404" do
    before do
      skip "curl is not installed" unless system("command -v curl >/dev/null 2>&1")
      @other_downloader = "wget"
      server.package_headers = { "X-Request-Id" => "req-40404" }
    end

    it "does not treat a successful download as a 404" do
      pending "do_curl greps every response header for 404 (fixed by chef/mixlib-install#442)"

      out, status = run_install("-v", "18.0.0")

      expect(status).to be_success, out
      expect(File.read(marker)).to eq("installed\n")
    end
  end

  it "rejects -f without a package extension for licensed downloads" do
    @other_downloader = "wget"
    out, status = run_install("-v", "18.0.0", "-L", "free-abc-123", "-f", File.join(workdir, "chef"))

    expect(status).not_to be_success
    expect(out).to include("-f must include the full package filename")
  end
end
