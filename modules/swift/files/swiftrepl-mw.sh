#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
# Launch swiftrepl on mediawiki-managed containers to ensure they are
# synchonized across sites. During normal operation FileBackend takes care of
# writing to both sites, however there might be occasional failures which will
# be taken care of by swiftrepl.

set -eu
set -o pipefail

logdir=${LOGDIR:-/var/log/swiftrepl}
srcdir=${SRCDIR:-/srv/software/swiftrepl}
num_threads=64
start_date=$(date -I)
# This script should only run in the active datacenter
active_dc=$(confctl --object-type mwconfig select 'name=WMFMasterDatacenter' get | jq -r '.WMFMasterDatacenter.val')
current_dc=$(cat /etc/wikimedia-cluster)
if [ "$active_dc" != "$current_dc" ]; then
    echo "Skipping execution, not the primary datacenter!"
    exit 0
fi

function run_swiftrepl() {
    local action=$1
    local containers=$2

    case "$action" in
    repl)
        args="-o"
        ;;
    del)
        args="-o -d"
        ;;
    *)
        echo "invalid action: $action"
        exit 1
        ;;
    esac

    case "$containers" in
    1 | commons)
        regexp='^wikipedia-commons-local-(public|deleted).[0-9a-z]{2}$'
        ;;
    2 | notcommons)
        regexp='^wikipedia-..-local-(public|deleted).[0-9a-z]{2}$'
        ;;
    3 | unsharded)
        regexp='^wik[a-z]+-.*-local-(public|deleted)$'
        ;;
    4 | global)
        regexp='^global-.*$'
        ;;
    5 | timeline)
        regexp='^wik[a-z]+-.*-timeline-render$'
        ;;
    6 | transcoded)
        regexp='^wik[a-z]+-.*-transcoded(.[0-9a-f]{2})?$'
        ;;
    7 | commons-thumbs)
        regexp='^wikipedia-commons-local-thumb.[0-9a-f]{2}$'
        ;;
    8 | unsharded-thumbs)
        regexp='^wik[a-z]+-.*-thumb$'
        ;;
    9 | notcommons-thumbs)
        regexp='^wikipedia-..-local-thumb.[0-9a-f]{2}$'
        ;;
    *)
        echo "invalid choice: $containers"
        exit 1
        ;;
    esac

    (cd $srcdir &&
        /usr/bin/time python ./swiftrepl.py "${num_threads}" "$regexp" -r "$args" 2>&1 \
            | ts '%Y-%m-%dT%H:%M:%.S' >> "${logdir}/${start_date}-${action}-${containers}.log")
}

action=$1
shift

for container in "$@"; do
    run_swiftrepl "$action" "$container"
done
