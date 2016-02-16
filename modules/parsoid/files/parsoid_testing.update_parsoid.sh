#!/bin/bash

set -e
set -u

echo 'Updating deploy repo checkout ...'
cd /srv/parsoid
git pull
echo 'Updating parsoid repo checkout ...'
cd src
git pull
git log -n 1
cd ..
echo 'Restarting parsoid ...'
sudo service parsoid restart
echo 'Restarting parsoid-rt testreduce clients ...'
sudo service parsoid-rt-client restart
echo 'All done!'
