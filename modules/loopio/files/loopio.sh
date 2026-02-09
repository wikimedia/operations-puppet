#!/bin/bash
# SPDX-License-Identifier: Apache-2.0

BASE_DIR="/var/lib/loopio"

stop_loop() {
    local name="$1"
    losetup --detach $(losetup --associated "${BASE_DIR}/${name}" --list --noheadings --output NAME)
}

start_loop() {
    local name="$1"
    losetup --find "${BASE_DIR}/${name}"
}

udev_name() {
    local devname="$1"
    local backfile
    backfile=$(losetup --noheadings --output BACK-FILE $devname)

    if [[ "$backfile" != "$BASE_DIR"/* ]]; then
        exit 1
    fi

    basename "$backfile"
}

if [[ $# -ne 2 ]]; then
    echo "Usage: $0 {--start|--stop|--udev-name} <name>"
    exit 1
fi

ACTION="$1"
NAME="$2"

case "$ACTION" in
    --stop)
        stop_loop "$NAME"
        ;;
    --start)
        start_loop "$NAME"
        ;;
    --udev-name)
        udev_name "$NAME"
        ;;
    *)
        echo "Unknown action: $ACTION"
        exit 1
        ;;
esac
