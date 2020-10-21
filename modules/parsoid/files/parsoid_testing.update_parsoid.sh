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
cd /srv/parsoid-testing

# Ensure we are in the master branch -- the repo has been
# left in a non-master checkout on occasion when a previous
# git pull might have failed for whatever reason.
git checkout master
git pull
git log -n 1
# Temporary hack to get Parsoid's RT testing client (still written
# in node.js) linked up to its npm modules (still hanging out in
# an otherwise-obsolete `deploy` repo).
ln -s -f /srv/deployment/parsoid/deploy/node_modules
