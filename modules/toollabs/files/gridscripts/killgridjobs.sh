#!/bin/bash
#
#
# THIS FILE IS MAINTAINED BY PUPPET
# source: modules/toollabs/files/gridscripts/
#
# This rescheduleds and/or kills all grid jobs running on the
#  specified hosts.
#
# Example:
#
# ./killjobs.sh tools-exec-1411 tools-exec-1412 tools-exec-1415
#

if [ `hostname` != 'tools-bastion-01' ]; then
    echo "This can only be run on a submit host.  Try tools-bastion-01."
    exit 1
fi
for host in "$@"
do
    echo Killing the following tasks:
    qhost -j -h $host | grep task
    qdel $(qhost -j -h $host |grep task|sed -e 's/^\s*//' | cut -d ' ' -f 1|egrep ^[0-9])
    sleep 5
done

echo Waiting 2m for tasks to clear
sleep 2m

for host in "$@"
do
    echo Rescheduling the following tasks:
    qhost -j -h "$host"
    qmod -rj $(qhost -j -h $host| sed -e 's/^\s*//' | cut -d ' ' -f 1|egrep ^[0-9])
    sleep 5
done
