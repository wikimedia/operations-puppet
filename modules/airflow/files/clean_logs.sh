#!/bin/bash
# SPDX-License-Identifier: Apache-2.0

# NOTE: This file is managed by Puppet.

# Deletes old files and directories in logs_folder older than specified days.
usage="$0 <logs_folder> <older_than_days>"

logs_folder="${1}"
if [ ! -e "${logs_folder}" ]; then
    echo "Error: logs_folder '${logs_folder}' does not exist."
    echo "${usage}"
    exit 1
fi

older_than_days="${2}"
if [ -z "${older_than_days}" ]; then
    echo "Error: Must specify <older_than_days>"
    echo "${usage}"
    exit 1
fi

echo "Deleting files and directories in ${logs_folder} older than ${older_than_days}..."
/usr/bin/find "${logs_folder}" -type f -mtime +"${older_than_days}" -delete && \
/usr/bin/find "${logs_folder}" -type d -mtime +"${older_than_days}" -empty -delete
