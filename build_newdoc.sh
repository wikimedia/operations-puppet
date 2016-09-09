#!/usr/bin/env bash
export BUNDLE_GEMFILE=Gemfile-doc
bundle install
bundle exec puppet strings server --modulepath=modules
