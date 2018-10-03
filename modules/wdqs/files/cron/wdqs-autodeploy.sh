#!/bin/bash
set -e

package_dir=$1

git -C $package_dir fetch
git -C $package_dir rebase
git -C $package_dir submodule update
git -C $package_dir fat pull

sudo service wdqs-updater stop
sudo service wdqs-blazegraph restart

sleep 10

sudo service wdqs-updater start
