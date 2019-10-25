#!/bin/bash

set -e

script="$(basename "$0")"
hostname="$(hostname -f)"
usage="Usage: ${script} <conftool_service> <service_name>"
conftool_service=${1:?$usage}
service_name=${2:?$usage}
selector="name=${hostname},service=${conftool_service}"

# Exit immediately if ats-be is not pooled
if confctl --quiet select "${selector}" get |
        jq ".[\"${hostname}\"].pooled" | grep -q '"no"'; then
    echo "${conftool_service} is depooled. Exiting." | logger -t "$script" --stderr
    exit 1
fi

echo "Depooling ${selector}" | logger -t "$script"
confctl --host --quiet select "${selector}" set/pooled=no

# Wait a bit for the service to be drained
sleep 30

/usr/sbin/service "${service_name}" restart

sleep 30

echo "Repooling ${selector}" | logger -t "$script"
confctl --host --quiet select "${selector}" set/pooled=yes
