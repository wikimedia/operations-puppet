#!/bin/bash
# This rescheduleds and/or kills all grid jobs running on the
#  specified hosts.
#
# Example:
#
# ./killjobs.sh tools-exec-1211 tools-exec-1212 tools-exec-1215
#

if [ `hostname` = 'tools-bastion-01' ]; then
    echo "This can only be run on tools-master."
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
