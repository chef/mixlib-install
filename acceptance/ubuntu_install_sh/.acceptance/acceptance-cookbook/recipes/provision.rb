# Generate install script then write to disk for terraform to copy to the instance for execution
execute "bundle exec ruby -e \"require 'mixlib/install'; puts Mixlib::Install.install_sh\" > ../.acceptance_data/ubuntu_install.sh" do
  cwd node['chef-acceptance']['suite-dir']
end

execute "terraform plan" do
  cwd "#{node['chef-acceptance']['suite-dir']}/terraform"
end

execute "terraform apply" do
  cwd "#{node['chef-acceptance']['suite-dir']}/terraform"
end
