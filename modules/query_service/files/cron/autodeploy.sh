#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
set -e

deploy_name=$1
package_dir=$2

echo "`date -u` - Query Service Starting autodeployment"

echo "git processes ongoing"
git -C $package_dir fetch
git -C $package_dir reset --hard HEAD
git -C $package_dir checkout origin/master
git -C $package_dir submodule update
git -C $package_dir fat pull

echo "restarting ${deploy_name}-blazegraph"
sudo service $deploy_name-blazegraph restart
echo "restarting ${deploy_name}-categories"
sudo service ${deploy_name}-categories restart

sleep 10

echo "restarting ${deploy_name}-updater"
sudo service ${deploy_name}-updater restart

echo "`date -u` - Query Service autodeployment - done"
