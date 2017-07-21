ruby_block "get ip" do
  block do
    tf_state = JSON.parse(File.read("#{node['chef-acceptance']['suite-dir']}/terraform/terraform.tfstate"))
    node.default["ip"] = tf_state["modules"].first["resources"]["aws_instance.mixlib_install_ps1"]["primary"]["attributes"]["public_ip"]
  end
end

execute "run inspec" do
  command lazy { "inspec exec verify.rb -t winrm://Administrator@#{node['ip']} --password $WINDOWS_PASSWORD" }
  cwd "#{node['chef-acceptance']['suite-dir']}/inspec"
  environment(
    "WINDOWS_PASSWORD" => ENV["TF_VAR_admin_password"] || "Pas5w0rD"
  )
end