# Check for chef-client command in various locations
for path in /usr/bin/chef-client /hab/pkgs/chef/chef-infra-client/*/*/bin/chef-client /opt/chef/bin/chef-client; do
  if test -x "$path" 2>/dev/null; then
    echo "$project installation detected at $path"
    echo "install_strategy set to 'once'"
    echo "Nothing to install"
    exit
  fi
done
