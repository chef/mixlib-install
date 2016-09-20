execute "bundle exec ruby -e \"require 'mixlib/install'; puts Mixlib::Install.install_sh\" > ../.acceptance_data/install.sh" do
  cwd node['chef-acceptance']['suite-dir']
end

execute "terraform plan" do
  cwd "#{node['chef-acceptance']['suite-dir']}/terraform"
end

execute "terraform apply" do
  cwd "#{node['chef-acceptance']['suite-dir']}/terraform"
end
