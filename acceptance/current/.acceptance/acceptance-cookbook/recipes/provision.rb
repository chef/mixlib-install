execute "bundle exec kitchen converge #{ENV["KITCHEN_INSTANCES"]}" do
  cwd node['chef-acceptance']['suite-dir']
end
