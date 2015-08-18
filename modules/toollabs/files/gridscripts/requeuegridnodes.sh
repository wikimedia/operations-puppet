#!/bin/bash
#
# Enable job queue for all args
#
# Example:
#
# ./requeue.sh tools-exec-1211 tools-exec-1212 tools-exec-1215
#
if [ `hostname` != 'tools-master' ]; then
    echo "This can only be run on tools-master."
    exit 1
fi
for node in "$@"
do
    qmod -e "*@${node}"
done
