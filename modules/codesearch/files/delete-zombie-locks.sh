#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
# Delete stale lock files older than X minutes.
# To prevent incidents like T421147.
#
# BASE_DIR (example: /srv/hound/)
# MIN_AGE  <minutes> (example: 60)
#
CONFIG_FILE="/etc/hound-delete-zombie-locks.conf"

if [[ -f "$CONFIG_FILE" ]]; then
    source "$CONFIG_FILE"
else
    echo "Error: Configuration file $CONFIG_FILE not found."
    exit 1
fi

if [[ -z ${BASE_DIR+x} || -z ${MIN_AGE+x} ]]; then
    echo "Error: Required parameters BASE_DIR or MIN_AGE are not set."
    exit 1
fi

echo "Cleaning locks in ${BASE_DIR} older than ${MIN_AGE} mins."

find "${BASE_DIR}" \
    \( -name "index.lock" -o -name "shallow.lock" \) \
    -path "*/.git/*" \
    -type f \
    -mmin +"${MIN_AGE}" \
    -print \
    -delete
