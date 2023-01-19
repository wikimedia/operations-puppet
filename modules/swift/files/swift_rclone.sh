#!/bin/bash
# SPDX-License-Identifier: Apache-2.0

# In theory, FileBackend should write all objects to both sites;
# in practice this isn't reliable, so we use rclone to sync both sites
# for a subset of containers (e.g. we don't bother with thumbnails).

set -eu
set -o pipefail

# This script should only run in the active datacenter
active_dc=$(confctl --object-type mwconfig select 'name=WMFMasterDatacenter' get | jq -r '.WMFMasterDatacenter.val')
local_dc=$(cat /etc/wikimedia-cluster)
if [ "$active_dc" != "$local_dc" ]; then
    echo "Skipping execution, not the primary datacenter!"
    exit 0
fi

case "$local_dc" in
    eqiad)
        remote_dc="codfw"
        ;;
    codfw)
        remote_dc="eqiad"
        ;;
    *)
        echo "Only codfw/eqiad replication supported"
        exit 1
        ;;
esac

#Set retries to 1 and --ignore-errors while we address
#the problem of missing objects still in container listings
#cf. T327269
rclone sync --checkers=64 --transfers=8 \
       --retries 1 --ignore-errors \
       --filter-from /etc/swift/swiftrepl_filters_nothumbs \
       --config /etc/swift/rclone.conf \
       --no-update-modtime \
       --use-mmap \
       --checksum \
       --swift-no-large-objects \
       "${local_dc}:" "${remote_dc}:"

