require "digest"
require "json"
require "webrick"

# A minimal stand-in for omnitruck and the commercial/trial download APIs,
# served from 127.0.0.1 so generated install scripts can be run end to end
# without network access or root.
#
# The "package" it serves is a shell script. install.sh installs a package
# whose filetype is "sh" by running it, so installing it only writes a marker
# file. Every request is recorded so specs can assert on the URLs the script
# built.
class FakeOmnitruck
  Request = Struct.new(:path, :query, :headers)

  PACKAGE_NAME = "chef-18.0.0-1.sh".freeze

  attr_reader :requests
  attr_accessor :metadata_status, :package_headers, :package_path_suffix, :sha256_override

  def initialize
    @requests = []
    @metadata_status = 200
    @package_headers = {}
    @package_path_suffix = "/files/stable/chef/18.0.0/#{PACKAGE_NAME}"
    @sha256_override = nil
    @server = WEBrick::HTTPServer.new(
      BindAddress: "127.0.0.1",
      Port: 0,
      Logger: WEBrick::Log.new(File::NULL),
      AccessLog: []
    )
    mount_routes
  end

  def start
    @thread = Thread.new { @server.start }
    self
  end

  def stop
    @server.shutdown
    @thread&.join(5)
  end

  def base_url
    "http://127.0.0.1:#{@server.config[:Port]}"
  end

  # Script body of the fake package: record that it was "installed".
  def package_body
    "#!/bin/sh\necho installed > \"$FAKE_INSTALL_MARKER\"\n"
  end

  def package_sha256
    sha256_override || Digest::SHA256.hexdigest(package_body)
  end

  def metadata_requests
    requests.select { |r| r.path.end_with?("/metadata") }
  end

  private

  def mount_routes
    @server.mount_proc("/") do |req, res|
      @requests << Request.new(req.path, WEBrick::HTTPUtils.parse_query(req.query_string.to_s), req.header)

      if req.path.end_with?("/metadata")
        serve_metadata(req, res)
      elsif req.path.start_with?("/files/") || req.path.end_with?("/download")
        serve_package(res)
      else
        res.status = 404
      end
    end
  end

  def serve_metadata(req, res)
    res.status = metadata_status
    return unless metadata_status == 200

    query = WEBrick::HTTPUtils.parse_query(req.query_string.to_s)
    if query["license_id"]
      # Licensed APIs answer with JSON and a /download URL without a filename
      res["Content-Type"] = "application/json"
      res.body = JSON.generate(
        "url" => "#{base_url}/stable/chef/download?v=18.0.0",
        "sha256" => package_sha256,
        "version" => "18.0.0"
      )
    else
      res["Content-Type"] = "text/plain"
      res.body = "sha1\tunused\nsha256\t#{package_sha256}\nurl\t#{base_url}#{package_path_suffix}\nversion\t18.0.0\n"
    end
  end

  def serve_package(res)
    res.status = 200
    res["Content-Type"] = "application/octet-stream"
    package_headers.each { |k, v| res[k] = v }
    res.body = package_body
  end
end
