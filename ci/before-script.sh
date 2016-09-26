#!/bin/bash

set -evx

# undo travis gem and bundler config
for ruby_env_var in _ORIGINAL_GEM_PATH \
                    BUNDLE_BIN_PATH \
                    BUNDLE_GEMFILE \
                    GEM_HOME \
                    GEM_PATH \
                    GEM_ROOT \
                    RUBYLIB \
                    RUBYOPT \
                    RUBY_ENGINE \
                    RUBY_ROOT \
                    RUBY_VERSION

do
  unset $ruby_env_var
done

# Don't run acceptance tests on forks. The decryption keys are not available.
if [ "${TRAVIS_REPO_SLUG}" = "chef/mixlib-install" ]; then

  # download terraform
  wget "https://releases.hashicorp.com/terraform/0.7.4/terraform_0.7.4_linux_amd64.zip"

   # inflate archive
   unzip terraform_0.7.4_linux_amd64.zip -d bin

   # decrypt pem
   openssl aes-256-cbc -K $encrypted_e2edbb28e76c_key -iv $encrypted_e2edbb28e76c_iv -in ci/es-infrastructure.pem.enc -out es-infrastructure.pem -d
   mkdir -p ~/.ssh
   mv es-infrastructure.pem ~/.ssh
fi
