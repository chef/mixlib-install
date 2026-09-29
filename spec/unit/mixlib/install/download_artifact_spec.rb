require "spec_helper"
require "tmpdir"

RSpec.describe Mixlib::Install, "#download_artifact" do
  subject(:installer) do
    described_class.new(
      product_name: "chef",
      channel: :stable,
      product_version: "18.0.0",
      platform: "ubuntu",
      platform_version: "22.04",
      architecture: "x86_64"
    )
  end

  let(:directory) { Dir.mktmpdir("download-artifact") }
  let(:url) { "https://packages.example.com/files/stable/chef/18.0.0/ubuntu/22.04/chef_18.0.0-1_amd64.deb" }
  let(:artifact) { Mixlib::Install::ArtifactInfo.new(url: url, version: "18.0.0") }

  before { allow(installer).to receive(:artifact_info).and_return(artifact) }
  after { FileUtils.rm_rf(directory) }

  def download
    installer.download_artifact(directory)
  end

  it "writes the package to the directory using the filename from the URL" do
    stub_request(:get, url).to_return(status: 200, body: "deb-bytes")

    file = download

    expect(file).to eq(File.join(directory, "chef_18.0.0-1_amd64.deb"))
    expect(File.binread(file)).to eq("deb-bytes")
  end

  it "creates the target directory when it does not exist" do
    stub_request(:get, url).to_return(status: 200, body: "x")
    nested = File.join(directory, "a", "b")

    file = installer.download_artifact(nested)

    expect(File.dirname(file)).to eq(nested)
  end

  it "preserves binary content byte for byte" do
    bytes = (0..255).map(&:chr).join.b * 4
    stub_request(:get, url).to_return(status: 200, body: bytes)

    expect(File.binread(download)).to eq(bytes)
  end

  context "with a query string in the URL" do
    let(:url) { "https://api.example.com/stable/chef/download?p=ubuntu&m=x86_64&v=18.0.0&license_id=free-123" }

    it "keeps the query string when requesting the file" do
      stub = stub_request(:get, url)
        .to_return(status: 200, body: "x", headers: { "Content-Disposition" => 'attachment; filename="chef_18.0.0-1_amd64.deb"' })

      download

      expect(stub).to have_been_requested.once
    end
  end

  context "when the server names the file with Content-Disposition" do
    let(:url) { "https://api.example.com/stable/chef/download?v=18.0.0&license_id=free-123" }

    it "uses a quoted filename" do
      stub_request(:get, url).to_return(status: 200, body: "x",
                                        headers: { "Content-Disposition" => 'attachment; filename="chef-18.0.0-1.el9.x86_64.rpm"' })

      expect(File.basename(download)).to eq("chef-18.0.0-1.el9.x86_64.rpm")
    end

    it "uses an unquoted filename" do
      stub_request(:get, url).to_return(status: 200, body: "x",
                                        headers: { "Content-Disposition" => "attachment; filename=chef-18.0.0-1.el9.x86_64.rpm" })

      expect(File.basename(download)).to eq("chef-18.0.0-1.el9.x86_64.rpm")
    end
  end

  context "when the server redirects" do
    let(:url) { "https://api.example.com/stable/chef/download?v=18.0.0&license_id=free-123" }
    let(:target) { "https://cdn.example.com/files/chef-18.0.0-1.el9.x86_64.rpm?token=abc" }

    it "follows the redirect and names the file from the final URL" do
      stub_request(:get, url).to_return(status: 302, headers: { "Location" => target })
      stub_request(:get, target).to_return(status: 200, body: "rpm-bytes")

      file = download

      expect(File.basename(file)).to eq("chef-18.0.0-1.el9.x86_64.rpm")
      expect(File.binread(file)).to eq("rpm-bytes")
    end

    it "resolves a relative Location against the original URL" do
      stub_request(:get, url).to_return(status: 301, headers: { "Location" => "/files/chef-18.0.0-1.el9.x86_64.rpm" })
      final = stub_request(:get, "https://api.example.com/files/chef-18.0.0-1.el9.x86_64.rpm").to_return(status: 200, body: "x")

      download

      expect(final).to have_been_requested
    end

    it "prefers Content-Disposition from the redirect target over the URL" do
      stub_request(:get, url).to_return(status: 302, headers: { "Location" => target })
      stub_request(:get, target).to_return(status: 200, body: "x",
                                           headers: { "Content-Disposition" => 'attachment; filename="named-by-header.rpm"' })

      expect(File.basename(download)).to eq("named-by-header.rpm")
    end

    it "keeps a Content-Disposition filename from the first response" do
      stub_request(:get, url).to_return(status: 302, headers: {
        "Location" => target,
        "Content-Disposition" => 'attachment; filename="from-first-hop.rpm"',
      })
      stub_request(:get, target).to_return(status: 200, body: "x",
                                           headers: { "Content-Disposition" => 'attachment; filename="from-second-hop.rpm"' })

      expect(File.basename(download)).to eq("from-first-hop.rpm")
    end

    it "follows at most five redirects" do
      hops = (0..6).map { |i| "https://cdn.example.com/hop#{i}" }
      stub_request(:get, url).to_return(status: 302, headers: { "Location" => hops[0] })
      hops.each_cons(2) { |from, to| stub_request(:get, from).to_return(status: 302, headers: { "Location" => to }) }

      download

      expect(a_request(:get, hops[4])).to have_been_made
      expect(a_request(:get, hops[5])).not_to have_been_made
    end
  end

  context "when neither the headers nor the final URL name a package" do
    let(:url) { "https://api.example.com/stable/chef/download" }

    it "falls back to the last path segment of the original URL" do
      stub_request(:get, url).to_return(status: 200, body: "x")

      expect(File.basename(download)).to eq("download")
    end
  end

  context "without platform options" do
    subject(:installer) { described_class.new(product_name: "chef", channel: :stable) }

    it "raises before making any request" do
      expect { download }.to raise_error(RuntimeError, /Must provide platform options/)
    end
  end
end
