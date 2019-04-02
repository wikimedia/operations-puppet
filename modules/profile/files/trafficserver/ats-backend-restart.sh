#!/bin/bash

set -e

script="$(basename "$0")"
hostname="$(hostname -f)"
selector="name=${hostname},service=ats-be"

# Exit immediately if ats-be is not pooled
if confctl --quiet select "${selector}" get |
        jq ".[\"${hostname}\"].pooled" | grep -q '"no"'; then
    echo "ats-be is depooled. Exiting." | logger -t "$script" --stderr
    exit 1
fi

echo "Depooling ${selector}" | logger -t "$script"
confctl --host --quiet select "${selector}" set/pooled=no

# Wait a bit for the service to be drained
sleep 30

/usr/sbin/service trafficserver restart

sleep 30

echo "Repooling ${selector}" | logger -t "$script"
confctl --host --quiet select "${selector}" set/pooled=yes
