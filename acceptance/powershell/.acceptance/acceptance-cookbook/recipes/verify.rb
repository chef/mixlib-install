ruby_block "get ip" do
  block do
    tf_state = JSON.parse(File.read("#{node['chef-acceptance']['suite-dir']}/terraform/terraform.tfstate"))
    node.default["private_ip"] = tf_state["modules"].first["resources"]["aws_instance.mixlib_install_ps1"]["primary"]["attributes"]["private_ip"]
  end
end

execute "run inspec" do
  command lazy { "inspec exec verify.rb -t winrm://Administrator@#{node['private_ip']} --password 'Pas5w0rD'" }
  cwd "#{node['chef-acceptance']['suite-dir']}/inspec"
end
