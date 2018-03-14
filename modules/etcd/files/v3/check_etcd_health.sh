#!/bin/bash
_host=${1:-localhost}
# Check the status of the local etcd server
HEALTH=$(/usr/bin/curl -s -L "https://${_host}:2379/health" | /usr/bin/jq '.health == "true"')

if [ "${HEALTH}" == "true" ]; then
    echo "The etcd server is healthy"
    exit 0
else
    echo "The etcd server is unhealthy"
    exit 2
fi
