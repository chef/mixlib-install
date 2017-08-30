# Generate install script then write to disk for terraform to copy to the instance for execution
execute "bundle exec ruby -e \"require 'mixlib/install'; puts Mixlib::Install.new(product_name: 'chef', product_version: :latest, channel: :stable, install_command_options: {download_url_override: 'https://packages.chef.io/files/stable/chef/13.2.20/ubuntu/14.04/chef_13.2.20-1_amd64.deb', cmdline_dl_dir: '/tmp/checksum'}).install_command\" > ../.acceptance_data/ubuntu_install_url.sh" do
  cwd node['chef-acceptance']['suite-dir']
end

execute "bundle exec ruby -e \"require 'mixlib/install'; puts Mixlib::Install.new(product_name: 'chef', product_version: :latest, channel: :stable, install_command_options: {download_url_override: 'https://packages.chef.io/files/stable/chef/13.2.20/ubuntu/14.04/chef_13.2.20-1_amd64.deb', checksum: '88cd274a694bfe23d255937794744d50af972097958fa681a544479e2bfb7f6b', cmdline_dl_dir: '/tmp/checksum'}).install_command\" > ../.acceptance_data/ubuntu_install_checksum.sh" do
  cwd node['chef-acceptance']['suite-dir']
end

execute "bundle exec ruby -e \"require 'mixlib/install'; puts Mixlib::Install.new(product_name: 'chef', product_version: :latest, channel: :stable, install_command_options: {cmdline_dl_dir: '/tmp/metadata'}).install_command\" > ../.acceptance_data/ubuntu_install_metadata.sh" do
  cwd node['chef-acceptance']['suite-dir']
end

execute "bundle exec ruby -e \"require 'mixlib/install'; puts Mixlib::Install.new(product_name: 'chef', product_version: :latest, channel: :stable, install_command_options: {download_url_override: 'https://packages.chef.io/files/stable/chef/13.2.20/ubuntu/14.04/chef_13.2.20-1_amd64.deb', checksum: 'FOOOOOOOOOOOOOO', cmdline_dl_dir: '/tmp/bad'}).install_command\" > ../.acceptance_data/ubuntu_install_bad.sh" do
  cwd node['chef-acceptance']['suite-dir']
end

execute "terraform plan" do
  cwd "#{node['chef-acceptance']['suite-dir']}/terraform"
end

execute "terraform apply" do
  cwd "#{node['chef-acceptance']['suite-dir']}/terraform"
end
