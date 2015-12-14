execute 'kitchen verify' do
  cwd node['chef-acceptance']['suite-dir']
end
