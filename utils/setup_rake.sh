#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
# BUNDLE_PATH: ".bundle/vendor"
# git clone "https://gerrit.wikimedia.org/r/operations/puppet"
apt-get -y install ruby-bundler ruby-dev make gcc g++
# TODO: we should use bndler config set but the version i tested with didn't have a version that suported that
mkdir .bundle
printf -- "---\nBUNDLE_PATH: \".bundle/vendor\"\nBUNDLE_PATH: \".bundle/vendor\"\n" > .bundle/config
bundle config set --local path '.bundle/vendor'
bundle install
