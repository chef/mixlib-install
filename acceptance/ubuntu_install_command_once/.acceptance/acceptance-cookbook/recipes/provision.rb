# Generate install script then write to disk for terraform to copy to the instance for execution
execute "bundle exec ruby -e \"require 'mixlib/install'; puts Mixlib::Install.new(product_name: 'chef', product_version: :latest, channel: :stable, install_command_options: {install_strategy: 'once'}).install_command\" > ../.acceptance_data/ubuntu_install_command_once.sh" do
  cwd node['chef-acceptance']['suite-dir']
end

execute "terraform plan" do
  cwd "#{node['chef-acceptance']['suite-dir']}/terraform"
end

execute "terraform apply" do
  cwd "#{node['chef-acceptance']['suite-dir']}/terraform"
end
