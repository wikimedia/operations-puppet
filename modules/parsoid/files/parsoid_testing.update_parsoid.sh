#!/bin/bash

set -e
set -u

# Stop parsoid-rt testreduce clients to eliminate
# any possibility of a race condition where the test clients
# notice the code change, restart, and query the parsoid service
# before it restarts with the new code. This should be a very very
# remote possibility, but doesn't hurt to do this right.
echo 'Stopping parsoid-rt testreduce clients ...'
sudo service parsoid-rt-client stop

echo 'Updating deploy repo checkout ...'
cd /srv/deployment/parsoid/deploy
# Ensure we are in the master branch -- the repo has been
# left in a non-master checkout on occasion when a previous
# git pull might have failed for whatever reason.
git checkout master
git pull

echo 'Updating parsoid repo checkout ...'
cd src
git checkout master
git pull
git log -n 1
# For Parsoid/PHP, symlink to the vendor/ directory in the
# deploy repo so that autoloading works as expected for the
# files in this directory.
# Temporary hack till we integrate Parsoid more fully into core.
# -f is needed to ensure we don't fail if the symlink already exists.
ln -s -f ../vendor

echo 'Restarting parsoid ...'
sudo service parsoid restart

echo 'Starting parsoid-rt testreduce clients ...'
sudo service parsoid-rt-client start

echo 'All done!'
