execute "terraform destroy -force" do
  cwd "#{node['chef-acceptance']['suite-dir']}/terraform"
end
