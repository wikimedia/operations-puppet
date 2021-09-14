#!/bin/bash
set -euo pipefail

device="$1"
dev_name=$(basename "$device")
label=$(lsblk -oname,label | grep "$dev_name" | awk '{print $2}')

if [[ "$label" =~ "ephemeral" ]]; then
    /sbin/pvcreate -f "$device"
    /sbin/vgcreate vd "$device"
else
    echo "$0: did not find applicable disk" >&2
    exit 1
fi
