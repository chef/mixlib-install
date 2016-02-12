execute "bundle exec kitchen verify #{ENV["KITCHEN_INSTANCES"]}" do
  cwd node['chef-acceptance']['suite-dir']
end
