# Check for product installation in various locations
if [ "$project" = "chef" ] || [ "$project" = "chef-ice" ]; then
  # For chef or chef-ice, look for chef-infra-client paths
  for path in /hab/pkgs/chef/chef-infra-client/*/*/bin /opt/chef/bin; do
    if test -d "$path" 2>/dev/null && test "x$install_strategy" = "xonce"; then
      echo "$project installation detected at $path"
      echo "install_strategy set to 'once'"
      echo "Nothing to install"
      exit
    fi
  done
else
  # For other products, look for product-specific paths
  for path in /hab/pkgs/chef/$project/*/*/bin /opt/$project/bin; do
    if test -d "$path" 2>/dev/null && test "x$install_strategy" = "xonce"; then
      echo "$project installation detected at $path"
      echo "install_strategy set to 'once'"
      echo "Nothing to install"
      exit
    fi
  done
fi
