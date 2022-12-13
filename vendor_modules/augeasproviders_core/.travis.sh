#!/bin/bash
set -xe

# Clone submodules in tree
git submodule update --init

# Use latest version of lenses
cd spec/fixtures/augeas && git pull origin master
PKG_VERSION=""

sudo add-apt-repository -y ppa:raphink/augeas
sudo apt-get update
sudo apt-get install augeas-tools${PKG_VERSION} \
                     augeas-lenses${PKG_VERSION} \
                     libaugeas0${PKG_VERSION} \
                     libaugeas-dev${PKG_VERSION} \
                     libxml2-dev

# Install gems
gem install bundler
bundle install

# Reporting only
bundle show
puppet --version
augtool --version
