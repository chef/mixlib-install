execute "bundle exec ruby -e \"require 'mixlib/install'; puts Mixlib::Install.install_ps1\" > ../.acceptance_data/install.ps1" do
  cwd node['chef-acceptance']['suite-dir']
end

execute "terraform plan" do
  cwd "#{node['chef-acceptance']['suite-dir']}/terraform"
end

execute "terraform apply" do
  cwd "#{node['chef-acceptance']['suite-dir']}/terraform"
end
