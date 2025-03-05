#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
# Convenience script to sync prometheus instance data from a source host

set -e
set -u

bwlimit="90MB"
base="/srv/prometheus"

if [ "$(whoami)" != "prometheus" ]; then
    echo "This script must be run as the 'prometheus' user."
    exit 1
fi

if [ "$#" -lt 2 ]; then
    echo "Usage: $0 <hostname> <instance1> [<instance2> ...]"
    exit 1
fi


source_host="$1"
shift

for instance in "$@"; do
    instance_dir="${base}/${instance}"
    if [ ! -d "${instance_dir}" ]; then
        echo "Directory ${instance_dir} not found for ${instance}. Aborting"
        exit 1
    fi

    rsync --verbose --archive --progress \
        --delete --bwlimit=${bwlimit} \
        "${source_host}::prometheus-data/${instance}/metrics/" \
        "${instance_dir}/metrics/"
done

