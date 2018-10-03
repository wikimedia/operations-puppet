#!/bin/bash
set -e

package_dir=$1

git -C $package_dir fetch
git -C $package_dir reset --hard HEAD
git -C $package_dir checkout origin/master
git -C $package_dir submodule update
git -C $package_dir fat pull

sudo service wdqs-blazegraph restart

sleep 10

sudo service wdqs-updater restart
