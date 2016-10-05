require "mixlib/install"
require "thor"

module Mixlib
  class Install
    class Cli < Thor
      include Thor::Actions

      desc "version", "print mixlib-install version"
      def version
        require "mixlib/install/version"
        say Mixlib::Install::VERSION
      end

      desc "list-versions PRODUCT_NAME CHANNEL", "list available version for a product/channel"
      def list_versions(product_name, channel)
        say Mixlib::Install.available_versions(product_name, channel).join("\n")
      end

      desc "download PRODUCT_NAME", "download an artifact"
      option :channel,
        default: :stable,
        aliases: ["-c"]
      option :version,
        default: :latest,
        aliases: ["-v"]
      option :directory,
        default: Dir.pwd,
        aliases: ["-d"]
      option :platform,
        aliases: ["-p"]
      option :platform_version,
        aliases: ["-l"]
      option :architecture,
        aliases: ["-a"]
      option :url,
        desc: "Print download URL without downloading the file",
        type: :boolean
      option :attributes,
        desc: "Print artifact attributes",
        type: :boolean
      def download(product_name)
        # Set mininum options
        mixlib_install_options = {
          channel: options[:channel].to_sym,
          product_name: product_name,
          product_version: options[:version],
        }

        # Set platform info or auto detect platform
        if options[:platform]
          if options[:platform_version].nil? || options[:architecture].nil?
            abort "Must provide platform version and architecture when specifying a platform"
          end
          mixlib_install_options[:platform] = options[:platform]
          mixlib_install_options[:platform_version] = options[:platform_version]
          mixlib_install_options[:architecture] = options[:architecture]
        else
          mixlib_install_options.merge!(Mixlib::Install.detect_platform)
        end

        say "Querying for artifact with options:\n#{JSON.pretty_generate(mixlib_install_options)}"
        artifact = Mixlib::Install.new(mixlib_install_options).artifact_info
        if artifact.nil? || artifact.is_a?(Array)
          abort "No results found."
        end

        if options[:url]
          say artifact.url
        else
          FileUtils.mkdir_p options[:directory]
          file = File.join(options[:directory], File.basename(artifact.url))

          require "json"
          require "net/http"

          say "Starting download #{artifact.url} to #{file}"
          uri = URI.parse(artifact.url)
          Net::HTTP.start(uri.host) do |http|
            resp = http.get(uri.path)
            open(file, "wb") do |io|
              io.write(resp.body)
            end
          end

          say "Download saved to #{file}"
        end

        say JSON.pretty_generate(artifact.to_hash) if options[:attributes]
      end

      desc "install-script", "generate install bootstrap script for shell or powershell"
      option :endpoint,
        desc: "Alternate omnitruck endpoint"
      option :file,
        desc: "Write script to file",
        aliases: ["-o"]
      option :type,
        desc: "Install script type: #{Mixlib::Install::Options::SUPPORTED_SHELL_TYPES.join(", ")}",
        aliases: ["-t"],
        default: "sh"
      def install_script
        if !Mixlib::Install::Options::SUPPORTED_SHELL_TYPES.include? options[:type].to_sym
          abort "type must be one of: #{Mixlib::Install::Options::SUPPORTED_SHELL_TYPES.join(", ")}"
        end
        context = {}
        context[:base_url] = options[:endpoint] if options[:endpoint]
        script = eval("Mixlib::Install.install_#{options[:type]}(context)")
        if options[:file]
          File.open(options[:file], "w") { |io| io.write(script) }
          say "Script written to #{options[:file]}"
        else
          say script
        end
      end
    end
  end
end
