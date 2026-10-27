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

# Only search the git clones (<instance>/data/vcs-*/.git). The index
# directories next to them (idx-*) are replaced by hound all the time,
# and walking them made find fail when one vanished during the run.
shopt -s nullglob
GIT_DIRS=("${BASE_DIR}"/*/data/vcs-*/.git)

if [[ ${#GIT_DIRS[@]} -eq 0 ]]; then
    echo "No git clones found in ${BASE_DIR}."
    exit 0
fi

find "${GIT_DIRS[@]}" \
    -ignore_readdir_race \
    \( -name "index.lock" -o -name "shallow.lock" \) \
    -type f \
    -mmin +"${MIN_AGE}" \
    -print \
    -delete
