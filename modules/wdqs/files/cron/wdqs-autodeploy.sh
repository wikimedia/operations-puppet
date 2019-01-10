#!/bin/bash
set -e

package_dir=$1

echo "`date -u` - WDQS Starting autodeployment"

echo "git processes ongoing"
git -C $package_dir fetch
git -C $package_dir reset --hard HEAD
git -C $package_dir checkout origin/master
git -C $package_dir submodule update
git -C $package_dir fat pull

echo "restarting wdqs-blazegraph"
sudo service wdqs-blazegraph restart
echo "restarting wdqs-categories"
sudo service wdqs-categories restart

sleep 10

echo "restarting wdqs-updater"
sudo service wdqs-updater restart

echo "`date -u` - WDQS autodeployment - done"
