execute 'kitchen destroy' do
  cwd node['chef-acceptance']['suite-dir']
end
