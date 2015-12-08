execute 'kitchen converge' do
  cwd node['chef-acceptance']['suite-dir']
end
