#!/bin/bash
# SPDX-License-Identifier: Apache-2.0

set -e

script="$(basename "$0")"
hostname="$(hostname -f)"
conftool_service="cdn"
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
