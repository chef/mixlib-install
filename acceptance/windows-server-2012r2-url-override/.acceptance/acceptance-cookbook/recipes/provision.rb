execute "bundle exec ruby -e \"require 'mixlib/install'; puts Mixlib::Install.install_ps1, 'install -download_url_override https://packages.chef.io/files/stable/chef/13.2.20/windows/2012r2/chef-client-13.2.20-1-x64.msi'\" > ../.acceptance_data/powershell_install_url_override.ps1" do
  cwd node['chef-acceptance']['suite-dir']
end

execute "terraform plan" do
  cwd "#{node['chef-acceptance']['suite-dir']}/terraform"
end

execute "terraform apply" do
  cwd "#{node['chef-acceptance']['suite-dir']}/terraform"
end

