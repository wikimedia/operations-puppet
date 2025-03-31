#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
set -euxo pipefail

if [ "$#" -ne 2 ]; then
    echo "Wrong number of arguments."
    echo "Usage: $0 <cluster name> <data dir>"
    exit 1
fi

CLUSTER_NAME="$1"
DATA_DIR="$2"
PID_FILE="/run/opensearch-${CLUSTER_NAME}/${CLUSTER_NAME}.pid"

if [ ! -r "$PID_FILE" ]; then
    echo "Didn't find pid file at ${PID_FILE}"
    echo "Is opensearch running for ${CLUSTER_NAME}?"
    exit 1
fi

/usr/bin/opensearch-madvise "$(cat "$PID_FILE")" "${DATA_DIR}"

echo "Done"
