# Check for chef-client command in various locations
for path in "/usr/bin/${project}-client" /hab/pkgs/chef/chef-infra-client/*/*/bin/chef-client "/opt/$project/bin/${project}-client"; do
  if test -x "$path" 2>/dev/null && test "x$install_strategy" = "xonce"; then
    echo "$project installation detected at $path"
    echo "install_strategy set to 'once'"
    echo "Nothing to install"
    exit
  fi
done
