#!/bin/bash

set -evx

# Don't run acceptance tests on forks. The decryption keys are not available.
if [ "${CHEF_ACCEPTANCE}" = "true" ] && [[ $encrypted_e2edbb28e76c_key ]]; then

  # download terraform
  wget "https://releases.hashicorp.com/terraform/0.7.4/terraform_0.7.4_linux_amd64.zip" -O tf.zip

   # inflate archive
   unzip tf.zip -d bin

   # decrypt pem
   openssl aes-256-cbc -K $encrypted_e2edbb28e76c_key -iv $encrypted_e2edbb28e76c_iv -in ci/es-infrastructure.pem.enc -out es-infrastructure.pem -d
   mkdir -p ~/.ssh
   mv es-infrastructure.pem ~/.ssh
fi
