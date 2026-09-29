require "spec_helper"
require "json"
require "mixlib/install/options"
require "mixlib/install/backend/package_router"

# Exercises the commercial and trial API code paths at the HTTP layer with
# WebMock, so the URLs, query parameters and error handling are covered and
# not just the parsing done after a stubbed #get.
RSpec.describe Mixlib::Install::Backend::PackageRouter, "licensed APIs" do
  let(:commercial) { Mixlib::Install::Dist::COMMERCIAL_API_ENDPOINT }
  let(:trial) { Mixlib::Install::Dist::TRIAL_API_ENDPOINT }
  let(:license_id) { "free-abc-123" }
  let(:product_name) { "chef" }
  let(:product_version) { :latest }
  let(:channel) { :stable }
  let(:platform_options) { {} }

  let(:options) do
    Mixlib::Install::Options.new({
      product_name: product_name,
      product_version: product_version,
      channel: channel,
      license_id: license_id,
    }.merge(platform_options))
  end

  subject(:router) { described_class.new(options) }

  def json(body)
    { status: 200, body: JSON.generate(body), headers: { "Content-Type" => "application/json" } }
  end

  def standard_packages(version)
    {
      "ubuntu" => {
        "22.04" => { "x86_64" => { "version" => version, "sha256" => "sha-ubuntu" } },
      },
      "el" => {
        "9" => {
          "x86_64" => { "version" => version, "sha256" => "sha-el-x86", "sha1" => "s1", "md5" => "m5" },
          "aarch64" => { "version" => version, "sha256" => "sha-el-arm" },
        },
      },
    }
  end

  describe "#available_versions" do
    it "reads versions/all with the license id and sorts them semantically" do
      stub = stub_request(:get, "#{commercial}/stable/chef/versions/all")
        .with(query: { "license_id" => license_id })
        .to_return(json(%w{18.10.17 17.10.3 18.2.7 18.10.17}))

      expect(router.available_versions).to eq(%w{17.10.3 18.2.7 18.10.17})
      expect(stub).to have_been_requested
    end

    it "raises ArtifactsNotFound when the channel has no versions" do
      stub_request(:get, "#{commercial}/stable/chef/versions/all").with(query: hash_including("license_id" => license_id)).to_return(json([]))

      expect { router.available_versions }.to raise_error(Mixlib::Install::Backend::ArtifactsNotFound, /product name: chef/)
    end
  end

  describe "#info without platform options" do
    before do
      stub_request(:get, "#{commercial}/stable/chef/versions/all")
        .with(query: { "license_id" => license_id })
        .to_return(json(%w{18.2.7 18.10.17 17.10.3}))
    end

    it "resolves the newest version by version order, not string order" do
      packages = stub_request(:get, "#{commercial}/stable/chef/packages")
        .with(query: { "v" => "18.10.17", "license_id" => license_id })
        .to_return(json(standard_packages("18.10.17")))

      artifacts = router.info

      expect(packages).to have_been_requested
      expect(artifacts.map(&:version).uniq).to eq(["18.10.17"])
    end

    context "with a partial version" do
      let(:product_version) { "18" }

      it "picks the newest matching release" do
        stub_request(:get, "#{commercial}/stable/chef/packages")
          .with(query: { "v" => "18.10.17", "license_id" => license_id })
          .to_return(json(standard_packages("18.10.17")))

        expect(router.info.first.version).to eq("18.10.17")
      end
    end

    it "flattens platform -> platform_version -> architecture into artifacts" do
      stub_request(:get, "#{commercial}/stable/chef/packages")
        .with(query: hash_including("v" => "18.10.17"))
        .to_return(json(standard_packages("18.10.17")))

      artifacts = router.info

      expect(artifacts.map { |a| [a.platform, a.platform_version, a.architecture] }).to contain_exactly(
        %w{ubuntu 22.04 x86_64}, %w{el 9 x86_64}, %w{el 9 aarch64}
      )
      el = artifacts.find { |a| a.platform == "el" && a.architecture == "x86_64" }
      expect(el).to have_attributes(sha256: "sha-el-x86", sha1: "s1", md5: "m5", product_name: "chef")
      expect(el.url).to eq("#{commercial}/stable/chef/download?p=el&pv=9&m=x86_64&v=18.10.17&license_id=#{license_id}")
    end

    it "understands the package-manager keyed structure used by habitat products" do
      stub_request(:get, "#{commercial}/stable/chef/packages")
        .with(query: hash_including("v" => "18.10.17"))
        .to_return(json(
          "linux" => {
            "x86_64" => { "deb" => { "version" => "18.10.17", "sha256" => "sha-deb" } },
            "aarch64" => { "rpm" => { "version" => "18.10.17", "sha256" => "sha-rpm" } },
          }
        ))

      artifacts = router.info

      expect(artifacts.map { |a| [a.platform, a.platform_version, a.architecture, a.sha256] }).to contain_exactly(
        ["linux", "", "x86_64", "sha-deb"], ["linux", "", "aarch64", "sha-rpm"]
      )
      expect(artifacts.map(&:url)).to all(include("license_id=#{license_id}"))
      expect(artifacts.map(&:url)).to all(satisfy { |u| !u.include?("&pv=") })
    end

    it "returns no artifacts when the packages endpoint returns 404" do
      stub_request(:get, "#{commercial}/stable/chef/packages").with(query: hash_including("license_id" => license_id)).to_return(status: 404)

      expect(router.info).to eq([])
    end

    it "raises on server errors instead of returning an empty list" do
      stub_request(:get, "#{commercial}/stable/chef/packages").with(query: hash_including("license_id" => license_id)).to_return(status: 500)

      expect { router.info }.to raise_error(Net::HTTPFatalError)
    end
  end

  describe "#info with platform options" do
    let(:product_version) { "18.10.17" }
    let(:platform_options) { { platform: "ubuntu", platform_version: "22.04", architecture: "x86_64" } }

    it "asks the metadata endpoint for exactly that platform" do
      stub = stub_request(:get, "#{commercial}/stable/chef/metadata")
        .with(query: { "v" => "18.10.17", "p" => "ubuntu", "pv" => "22.04", "m" => "x86_64", "license_id" => license_id })
        .to_return(json("version" => "18.10.17", "sha256" => "sha-meta", "url" => "ignored"))

      artifact = router.info

      expect(stub).to have_been_requested
      expect(artifact).to have_attributes(version: "18.10.17", sha256: "sha-meta", platform: "ubuntu", platform_version: "22.04")
      expect(artifact.url).to eq("#{commercial}/stable/chef/download?p=ubuntu&pv=22.04&m=x86_64&v=18.10.17&license_id=#{license_id}")
    end

    context "and a latest or partial version" do
      let(:product_version) { "18" }

      it "requests v=latest" do
        stub = stub_request(:get, "#{commercial}/stable/chef/metadata")
          .with(query: hash_including("v" => "latest"))
          .to_return(json("version" => "18.10.17", "sha256" => "x"))

        router.info

        expect(stub).to have_been_requested
      end
    end

    [400, 404].each do |status|
      it "reports ArtifactsNotFound on HTTP #{status}" do
        stub_request(:get, "#{commercial}/stable/chef/metadata")
          .with(query: hash_including("license_id" => license_id)).to_return(status: status)

        expect { router.info }.to raise_error(Mixlib::Install::Backend::ArtifactsNotFound, /platform: ubuntu/)
      end
    end

    it "reports ArtifactsNotFound for an empty metadata document" do
      stub_request(:get, "#{commercial}/stable/chef/metadata")
        .with(query: hash_including("license_id" => license_id)).to_return(json({}))

      expect { router.info }.to raise_error(Mixlib::Install::Backend::ArtifactsNotFound)
    end

    it "raises on server errors" do
      stub_request(:get, "#{commercial}/stable/chef/metadata")
        .with(query: hash_including("license_id" => license_id)).to_return(status: 503)

      expect { router.info }.to raise_error(Net::HTTPFatalError)
    end
  end

  describe "requests" do
    it "send the mixlib-install user agent" do
      stub = stub_request(:get, "#{commercial}/stable/chef/versions/all")
        .with(query: hash_including("license_id" => license_id)) { |req| Array(req.headers["User-Agent"]).join(", ").include?("mixlib-install/") }
        .to_return(json(%w{18.0.0}))

      router.available_versions

      expect(stub).to have_been_requested
    end
  end

  context "with a trial license" do
    let(:license_id) { "trial-xyz-789" }

    it "skips version listing and asks for the latest packages directly" do
      packages = stub_request(:get, "#{trial}/stable/chef/packages")
        .with(query: { "v" => "latest", "license_id" => license_id })
        .to_return(json(standard_packages("18.10.17")))

      router.info

      expect(packages).to have_been_requested
      expect(a_request(:get, %r{/versions/all})).not_to have_been_made
    end

    context "with a channel and version the trial API does not serve" do
      let(:channel) { :current }
      let(:product_version) { "17.0.0" }

      it "is coerced to the stable channel and the latest version" do
        packages = stub_request(:get, "#{trial}/stable/chef/packages")
          .with(query: { "v" => "latest", "license_id" => license_id })
          .to_return(json(standard_packages("18.10.17")))

        expect { router.info }
          .to output(/Changing from 'current' to 'stable'.*Changing from '17.0.0' to 'latest'/m).to_stderr

        expect(packages).to have_been_requested
      end
    end
  end
end
