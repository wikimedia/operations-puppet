#!/bin/bash

# Init
SCRIPT_PATH=$(pwd)
BASENAME_CMD="basename ${SCRIPT_PATH}"
SCRIPT_BASE_PATH=`eval ${BASENAME_CMD}`

if [ $SCRIPT_BASE_PATH = "test_run_scripts" ]; then
  cd ../
fi

export pe_dist_dir="http://enterprise.delivery.puppetlabs.net/2015.3/ci-ready"
export GEM_SOURCE=http://rubygems.delivery.puppetlabs.net

bundle install --without build development test --path .bundle/gems

bundle exec beaker \
  --preserve-host \
  --host configs/redhat-6-64mda.yml \
  --debug \
  --pre-suite pre-suite \
  --tests tests \
  --keyfile ~/.ssh/id_rsa-acceptance \
  --load-path lib
