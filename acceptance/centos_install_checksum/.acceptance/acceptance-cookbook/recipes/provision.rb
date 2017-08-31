# Generate install script then write to disk for terraform to copy to the instance for execution
execute "bundle exec ruby -e \"require 'mixlib/install'; puts Mixlib::Install.new(product_name: 'chef', product_version: :latest, channel: :stable, install_command_options: {download_url_override: 'https://packages.chef.io/files/stable/chef/13.3.42/el/7/chef-13.3.42-1.el7.x86_64.rpm', cmdline_dl_dir: '/tmp/checksum'}).install_command\" > ../.acceptance_data/centos_install_url.sh" do
  cwd node['chef-acceptance']['suite-dir']
end

execute "bundle exec ruby -e \"require 'mixlib/install'; puts Mixlib::Install.new(product_name: 'chef', product_version: :latest, channel: :stable, install_command_options: {download_url_override: 'https://packages.chef.io/files/stable/chef/13.3.42/el/7/chef-13.3.42-1.el7.x86_64.rpm', checksum: 'fe051b504856a74ccce1fd23ff92c296506cb8292a3933c71069ae915e7a4a00', cmdline_dl_dir: '/tmp/checksum'}).install_command\" > ../.acceptance_data/centos_install_checksum.sh" do
  cwd node['chef-acceptance']['suite-dir']
end

execute "bundle exec ruby -e \"require 'mixlib/install'; puts Mixlib::Install.new(product_name: 'chef', product_version: :latest, channel: :stable, install_command_options: {cmdline_dl_dir: '/tmp/metadata'}).install_command\" > ../.acceptance_data/centos_install_metadata.sh" do
  cwd node['chef-acceptance']['suite-dir']
end

execute "bundle exec ruby -e \"require 'mixlib/install'; puts Mixlib::Install.new(product_name: 'chef', product_version: :latest, channel: :stable, install_command_options: {download_url_override: 'https://packages.chef.io/files/stable/chef/13.3.42/el/7/chef-13.3.42-1.el7.x86_64.rpm', checksum: 'FOOOOOOOOOOOOOO', cmdline_dl_dir: '/tmp/bad'}).install_command\" > ../.acceptance_data/centos_install_bad.sh" do
  cwd node['chef-acceptance']['suite-dir']
end

execute "terraform plan" do
  cwd "#{node['chef-acceptance']['suite-dir']}/terraform"
end

execute "terraform apply" do
  cwd "#{node['chef-acceptance']['suite-dir']}/terraform"
end
