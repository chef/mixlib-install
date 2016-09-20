#!/bin/sh

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


# set chefdk as default environment
eval "$(/opt/chefdk/bin/chef shell-init bash)"

# download terraform
wget "https://releases.hashicorp.com/terraform/0.7.4/terraform_0.7.4_linux_amd64.zip"

# inflate archive
unzip terraform_0.7.4_linux_amd64.zip -d bin

# put terraform on PATH
export PATH="$PWD/bin:$PATH"

# decrypt pem
openssl aes-256-cbc -K $encrypted_e2edbb28e76c_key -iv $encrypted_e2edbb28e76c_iv -in ci/es-infrastructure.pem.enc -out es-infrastructure.pem -d
mkdir -p ~/.ssh
mv es-infrastructure.pem ~/.ssh
