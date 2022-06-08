#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
# For each datacenter, fetches dbconfig JSON from etcd and places it under
# e.g. /srv/dbconfig/eqiad.json.
#
# Runs via a systemd timer.

set -eu
set -o pipefail

OUTPUT_PATH=/srv/dbconfig

# Given a service name (e.g. etcd) and optional protocol (e.g. tcp),
# resolves a DNS SRV record into a host:port.
function resolve-srv () {
    SERVICE=$1
    [ -z "$1" ] && return 1
    PROTO=${2:-tcp}
    dig _${SERVICE}._${PROTO} srv +short +ndots=2 +search | grep -ve '^$' | shuf -n1 | awk '{print $4 ":" $3}'
}

ETCD=$(resolve-srv etcd)

for DC in eqiad codfw; do
    ETCD_KEY="conftool/v1/mediawiki-config/${DC}/dbconfig"
    # Extract and unescape the value from the response of etcd's JSON API.
    # That yields a dbconfig JSON dict with val: <data we want>; extract that
    # and write it out.
    curl -s -m15 "https://${ETCD}/v2/keys/${ETCD_KEY}" | jq -er .node.value | jq -Ser .val > ${OUTPUT_PATH}/.${DC}.json.tmp
    [ $? -eq 0 ] && mv $OUTPUT_PATH/.${DC}.json.tmp $OUTPUT_PATH/${DC}.json
done
