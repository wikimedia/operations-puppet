#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
# =========This file is managed by puppet. DO NOT EDIT=========

# Send logs from specified namespaces to journald

set -o errexit
set -o pipefail
set -o nounset

LOG_DIR="/var/log/pods"
LOG_TAG="k8s-namespace-logs"

echo_error() {
    echo "ERROR: $1" >&2
    exit 1
}

if [[ $# -gt 0 ]]; then
    NAMESPACES=("$@")
else
    echo_error "Could not get list of namespaces from script args.
    You need to pass a list of namespaces to this script
    e.g. ./script.sh namespace1 namespace2"
fi

if [[ ! -d "$LOG_DIR" ]]; then
    echo_error "Log directory $LOG_DIR does not exist."
fi

for NAMESPACE in "${NAMESPACES[@]}"; do
    # Find all log files in the directory prefixed with the namespace
    if ! find "$LOG_DIR" -wholename "${LOG_DIR}/${NAMESPACE}_*.log" | grep -q '.'; then
        echo "WARNING: No log files found for namespace $NAMESPACE."
        continue
    fi
    find "$LOG_DIR" -wholename "${LOG_DIR}/${NAMESPACE}_*.log" | while read -r LOG_FILE; do

        POD=$(echo "$LOG_FILE" | awk -F'/' '{print $5}' | cut -d'_' -f2)
        CONTAINER=$(echo "$LOG_FILE" | awk -F'/' '{print $6}')

        # verify that log.idx file exists and if not, create it.
        CURRENT_LINE_IDX_FILE="${LOG_FILE}.idx"
        if [[ ! -f "$CURRENT_LINE_IDX_FILE" ]]; then
            echo "1" > "$CURRENT_LINE_IDX_FILE"
        fi
        CURRENT_LINE_IDX=$(cat "$CURRENT_LINE_IDX_FILE")

        # Get lines to process
        LINES_TO_PROCESS=$(tail -n+"${CURRENT_LINE_IDX}" "$LOG_FILE")

        # Process lines
        while read -r LOG_LINE; do

            logger --journald <<EOF
SYSLOG_IDENTIFIER=$LOG_TAG
NAMESPACE=$NAMESPACE
POD=$POD
CONTAINER=$CONTAINER
MESSAGE=$LOG_LINE
EOF
        done <<< "$LINES_TO_PROCESS"

        # update idx file with the index of the next line to process
        COUNT=$(echo "$LINES_TO_PROCESS" | wc -l)
        echo "$((CURRENT_LINE_IDX + COUNT))" > "$CURRENT_LINE_IDX_FILE"
    done
done
