Important Note!

Before running chef-acceptance, you MUST do the following on your current session:

`export APPBUNDLER_ALLOW_RVM=true`

`bundle install --binstubs`

`bundle exec berks-monolith vendor .shared`

`bin/chef-acceptance test`
