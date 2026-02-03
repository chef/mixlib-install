# Check for product installation in various locations
if [ "$project" = "chef" ] || [ "$project" = "chef-ice" ]; then
  # For chef or chef-ice, look for chef-infra-client paths
  install_paths="/hab/pkgs/chef/chef-infra-client/*/*/bin /opt/chef/bin"
else
  # For other products, look for product-specific paths
  install_paths="/hab/pkgs/chef/$project/*/*/bin /opt/$project/bin"
fi

for path in $install_paths; do
  if [ -d "$path" ] 2>/dev/null && [ "$install_strategy" = "once" ]; then
    echo "$project installation detected at $path"
    echo "install_strategy set to 'once'"
    echo "Nothing to install"
    exit
  fi
done
