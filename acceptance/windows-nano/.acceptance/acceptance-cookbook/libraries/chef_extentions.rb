class Chef
  class Recipe
    def run_tf(command)
      execute "terraform #{command}" do
        cwd "#{node['chef-acceptance']['suite-dir']}/terraform"
      end
    end
  end

  class Resource
    def instance_ip
      @instance_ip ||= tf_state["modules"].first["resources"]["aws_instance.windows_server_nano_ami"]["primary"]["attributes"]["public_ip"]
    end

    def instance_id
      @instance_id ||= tf_state["modules"].first["resources"]["aws_instance.windows_server_nano_ami"]["primary"]["id"]
    end

    def windows_password
      @windows_password ||= begin
        require "aws-sdk"

        ec2 = Aws::EC2::Resource.new
        instance = ec2.instance(instance_id)
        instance.wait_until_running

        # AWS periodically needs more time to retrieve the windows password. Retry.
        time = 3 * 60 # try up to 3 minutes
        interval = 5 # every 5 seconds
        tries = time / interval
        begin
          password = instance.decrypt_windows_password("#{ENV['HOME']}/.ssh/es-infrastructure.pem")
        rescue RuntimeError => e
          if e.message =~ /password not available yet/
            unless (tries -= 1).zero?
              sleep interval
              retry
            end
          else
            raise e
          end
        end

        password
      end
    end

    def run_shell(script, type = :powershell)
      require "winrm"

      opts = { 
        endpoint: "http://#{instance_ip}:5985/wsman",
        user: "Administrator",
        password: windows_password
      }

      conn = WinRM::Connection.new(opts)

      conn.shell(type) do |shell|
        output = shell.run(script) do |stdout, stderr|
          STDOUT.print stdout
          STDERR.print stderr
        end
        Chef::Log.info "The script exited with exit code #{output.exitcode}"
      end
    end

    private

    def tf_state
      @tfstate ||= JSON.parse(::File.read("#{node['chef-acceptance']['suite-dir']}/terraform/terraform.tfstate"))
    end
  end
end
