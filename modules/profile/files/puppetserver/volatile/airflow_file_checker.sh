#!/bin/bash
# SPDX-License-Identifier: Apache-2.0

set -e

CONFIG_DIR="$1"
TARGET_PROM_FILE="/var/lib/prometheus/node.d/airflow_haproxy_file_checks.prom"
TMP_PROM_FILE="/tmp/airflow_haproxy_file_checks.prom"

echo -n "" > "$TMP_PROM_FILE"

for filepath in "$CONFIG_DIR"/*_haproxy_config; do
    [ -e "$filepath" ] || continue
    filename=$(basename "$filepath")
    lines=$(wc -l < "$filepath")
    echo "sre_airflow_file_output_lines{name=\"${filename}\"} ${lines}" >> "$TMP_PROM_FILE"
done
mv $TMP_PROM_FILE $TARGET_PROM_FILE