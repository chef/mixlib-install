run_tf "plan"

run_tf "apply"

ruby_block "install via winrm api" do
  block do
    # We do this hackery to ensure we load mixlib-install from source
    install_command = "install -project angry-omnibus-toolchain -channel current -version 1.1.57"

    shellout_command = <<-EOF.gsub /^\s*/, ""
      bundle exec ruby -e "require 'mixlib/install';\
      puts Mixlib::Install.install_ps1, '#{install_command}'"
    EOF

    require "mixlib/shellout"

    print_script = Mixlib::ShellOut.new(
      shellout_command,
      cwd: node['chef-acceptance']['suite-dir']
    )
    print_script.run_command

    run_shell(print_script.stdout)
  end
end

ruby_block "set omnibus paths" do
  block do
    toolchain_install_dir = File.join('c:', 'opscode', 'angry-omnibus-toolchain')

    omnibus_env = []
    omnibus_env << File.join(toolchain_install_dir, 'embedded', 'bin')
    omnibus_env << File.join(toolchain_install_dir, 'embedded', 'bin', 'mingw64', 'bin')
    omnibus_env << File.join(toolchain_install_dir, 'embedded', 'bin', 'usr', 'bin')
    omnibus_env << File.join(toolchain_install_dir, 'embedded', 'git', 'cmd')
    omnibus_env << File.join(toolchain_install_dir, 'embedded', 'git', 'mingw64', 'libexec', 'git-core')

    # Join paths by semi-colons then replace forwardslashes with backslashes
    omnibus_path = omnibus_env.join(";").gsub("/", "\\")

    # Permanently set omnibus path to machine PATH
    script = <<-EOF.gsub /^\s*/, ""
      $env:path += ';#{omnibus_path}'
      setx PATH $env:path /M
    EOF

    run_shell(script)
  end
end
