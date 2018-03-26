#!/bin/bash
_endpoint=${1:-http://localhost:2379}
# Check the status of the local etcd server
HEALTH=$(/usr/bin/curl -s -L "${_endpoint}/health" | /usr/bin/jq '.health == "true"')

if [ "${HEALTH}" == "true" ]; then
    echo "The etcd server is healthy"
    exit 0
else
    echo "The etcd server is unhealthy"
    exit 2
fi
