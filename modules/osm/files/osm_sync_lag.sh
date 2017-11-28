#!/bin/bash

set -e
set -u

state_path=${1:-"/srv/osmosis/state.txt"}
prometheus_path=${2:-"/var/lib/prometheus/node.d/osm_sync_lag.prom"}

timestamp=$(awk -F= '/^timestamp=/ { print $2 }' $state_path | tr -d \\\\)
lag=$(date "+%s" --date=${timestamp})
echo "osm_sync_timestamp" $lag > $prometheus_path.$$
mv $prometheus_path.$$ $prometheus_path
