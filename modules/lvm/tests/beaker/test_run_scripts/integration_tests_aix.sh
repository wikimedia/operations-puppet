#!/bin/bash

# Init
SCRIPT_PATH=$(pwd)
BASENAME_CMD="basename ${SCRIPT_PATH}"
SCRIPT_BASE_PATH=`eval ${BASENAME_CMD}`

if [ $SCRIPT_BASE_PATH = "test_run_scripts" ]; then
  cd ../
fi

export pe_dist_dir="http://pe-releases.puppetlabs.lan/2015.3.3"
export GEM_SOURCE=http://rubygems.delivery.puppetlabs.net

bundle install --without build development test --path .bundle/gems

bundle exec beaker \
  --no-provision \
  --host configs/aix-71-spec.yml \
  --debug \
  --pre-suite pre-suite \
  --tests tests/aix \
  --keyfile ~/.ssh/id_rsa-acceptance \
  --load-path lib
