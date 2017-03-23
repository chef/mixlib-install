execute "run inspec" do
  command lazy { "inspec exec verify.rb -t winrm://Administrator@#{instance_ip} --password $WINDOWS_PASSWORD" }
  cwd "#{node['chef-acceptance']['suite-dir']}/inspec"
  environment(
    lazy {
      { "WINDOWS_PASSWORD" => windows_password }
    }
  )
end
