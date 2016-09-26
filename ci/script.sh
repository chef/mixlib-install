#!/bin/bash

set -evx

# run unit tests
/opt/chefdk/embedded/bin/bundle install && /opt/chefdk/bin/chef exec rake

# Don't run acceptance tests on forks. The decryption keys are not available.
if [ "${TRAVIS_REPO_SLUG}" = "chef/mixlib-install" ]; then
  # setup acceptance tests
  cd acceptance && export BUNDLE_GEMFILE=$PWD/Gemfile && /opt/chefdk/embedded/bin/bundle install && export APPBUNDLER_ALLOW_RVM=true
  # run acceptances tests and force cleanup
  # only testing bourne until issues with powershell suite resovled:
  # 1) inspec not finding chef package once connected (not reproducible locally)
  # 2) currently no way to mask password (sensitive true) AND know what the error is if inspec fails
  /opt/chefdk/embedded/bin/bundle exec chef-acceptance test bourne --force-destroy
fi
