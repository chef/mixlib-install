execute "bundle exec ruby -e \"require 'mixlib/install'; puts Mixlib::Install.new(product_name: 'omnibus-toolchain', product_version: :latest, channel: :stable).install_command\" > ../.acceptance_data/ubuntu_install_command.sh" do
  cwd node['chef-acceptance']['suite-dir']
end

execute "terraform plan" do
  cwd "#{node['chef-acceptance']['suite-dir']}/terraform"
end

execute "terraform apply" do
  cwd "#{node['chef-acceptance']['suite-dir']}/terraform"
end
