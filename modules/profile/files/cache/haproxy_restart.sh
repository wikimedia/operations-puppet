#!/bin/bash

set -e

script="$(basename "$0")"
hostname="$(hostname -f)"
#TODO: This will be renamed as soon as we get rid of ats-tls
conftool_service="ats-tls"
selector="name=${hostname},service=${conftool_service}"

# Exit immediately if the service is not pooled
if confctl --quiet select "${selector}" get |
        jq ".[\"${hostname}\"].pooled" | grep -q '"no"'; then
    echo "${conftool_service} is depooled. Exiting." | logger -t "$script" --stderr
    exit 1
fi

echo "Depooling ${selector}" | logger -t "$script"
confctl --host --quiet select "${selector}" set/pooled=no

# Wait a bit for the service to be drained
sleep 30

/usr/bin/systemctl restart haproxy.service

sleep 30

echo "Repooling ${selector}" | logger -t "$script"
confctl --host --quiet select "${selector}" set/pooled=yes
