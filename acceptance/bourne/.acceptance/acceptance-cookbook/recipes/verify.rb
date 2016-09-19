ruby_block "get ip" do
  block do
    tf_state = JSON.parse(File.read("#{node['chef-acceptance']['suite-dir']}/terraform/terraform.tfstate"))
    node.default["ip"] = tf_state["modules"].first["resources"]["aws_instance.mixlib_install_sh"]["primary"]["attributes"]["public_ip"]
  end
end

execute "run inspec" do
  command lazy { "inspec exec verify.rb -t ssh://ubuntu@#{node['ip']} -i ~/.ssh/es-infrastructure.pem" }
  cwd "#{node['chef-acceptance']['suite-dir']}/inspec"
end
