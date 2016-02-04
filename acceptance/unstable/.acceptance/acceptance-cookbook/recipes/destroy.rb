execute "bundle exec kitchen destroy #{ENV["KITCHEN_INSTANCES"]}" do
  cwd node['chef-acceptance']['suite-dir']
end
