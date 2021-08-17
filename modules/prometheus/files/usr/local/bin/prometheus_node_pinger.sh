#!/bin/bash
PING_TIMEOUT_S=5
COUNT=1

set -eu

help() {
    cat <<EOH
Usage: $0 HOST_TO_PING [HOST_TO_PING [...]]

This script is used to export for prometheus the latencies of pinging the given nodes.
Meant to be used by the file node exporter.

Arguments
    HOST_TO_PING [HOST_TO_PING [...]]
    Hosts, separated by space, to generate the stats for.
EOH
}




if [[ "${1:-}" == "-h" ]]; then
    help
    exit 0
elif [[ "${1:-}" == "-x" ]]; then
    set -x
    shift
fi

if [[ "${1:-}" == "" ]]; then
    help
    exit 1
fi


for host in "$@"; do
    host_rtt=$( \
        ping \
            -c "$COUNT" \
            -W "$PING_TIMEOUT_S" \
            -q \
            "$host" \
            2>/dev/null \
        | grep min \
        | awk '{print $4}' \
        | grep -o '^[^/]*' \
        || echo '-1'
    )
    cat <<EOD
node_ping_latency{dst_host="$host",src_host="$HOSTNAME"} $host_rtt
EOD
done
