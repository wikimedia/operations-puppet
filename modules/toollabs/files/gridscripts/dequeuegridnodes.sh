#!/bin/bash
#
# THIS FILE IS MAINTAINED BY PUPPET
# source: modules/toollabs/files/gridscripts/
#
# Disable job queue for all args
#
# Example:
#
# ./dequeue.sh tools-exec-1411 tools-exec-1412 tools-exec-1415
#
if [ `hostname` != 'tools-master' ]; then
    echo "This can only be run on tools-master."
    exit 1
fi
for node in "$@"
do
    qmod -d "*@${node}"
done
