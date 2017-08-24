# Nothing to see here...

install_url = "install -download_url_override https://packages.chef.io/files/stable/chef/13.2.20/windows/2012r2/chef-client-13.2.20-1-x64.msi"

execute "bundle exec ruby -e \"require 'mixlib/install'; puts Mixlib::Install.install_ps1, '#{install_url}'\" > ../.acceptance_data/powershell_install_url.ps1" do
  cwd node['chef-acceptance']['suite-dir']
end

install_checksum = "#{install_url} -checksum 82772d31ad110b7a584492f3a51358a56f4d706a41920c0d441b87c94b71336c -verbose"

execute "bundle exec ruby -e \"require 'mixlib/install'; puts Mixlib::Install.install_ps1, '#{install_checksum}'\" > ../.acceptance_data/powershell_install_checksum.ps1" do
  cwd node['chef-acceptance']['suite-dir']
end

execute "terraform plan" do
  cwd "#{node['chef-acceptance']['suite-dir']}/terraform"
end

execute "terraform apply" do
  cwd "#{node['chef-acceptance']['suite-dir']}/terraform"
end

