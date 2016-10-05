execute "bundle exec ruby -e \"require 'mixlib/install'; puts Mixlib::Install.install_ps1, 'install'\" > ../.acceptance_data/powershell_install.ps1" do
  cwd node['chef-acceptance']['suite-dir']
end

execute "terraform plan" do
  cwd "#{node['chef-acceptance']['suite-dir']}/terraform"
end

execute "terraform apply" do
  cwd "#{node['chef-acceptance']['suite-dir']}/terraform"
end

