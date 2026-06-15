#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# WARNING: This file is managed by Puppet.
# Source: modules/beta/files/stream_master.sh
set -euo pipefail

echo2() {
    echo "$@" >&2
}

detect_mariadb_bin_dir() {
    local mariadb_dirs mariadb_bin_dir

    shopt -s nullglob
    mariadb_dirs=(/opt/wmf-mariadb*)
    shopt -u nullglob

    if [ "${#mariadb_dirs[@]}" -eq 0 ]; then
        echo2 "ERROR: No /opt/wmf-mariadb* directory found."
        exit 1
    fi

    if [ "${#mariadb_dirs[@]}" -gt 1 ]; then
        echo2 "ERROR: Multiple /opt/wmf-mariadb* directories found:"
        printf '  %s\n' "${mariadb_dirs[@]}" >&2
        exit 1
    fi

    mariadb_bin_dir="${mariadb_dirs[0]}/bin"
    if [ ! -d "${mariadb_bin_dir}" ]; then
        echo2 "ERROR: MariaDB bin directory does not exist: ${mariadb_bin_dir}"
        exit 1
    fi

    echo "${mariadb_bin_dir}"
}

if [ $# -ne 1 ]; then
    echo "Usage: $0 <replica_hostname>" >&2
    exit 1
fi

REPLICA_HOST="$1"
TRANSFER_PORT=1234
MARIADB_BIN_DIR="$(detect_mariadb_bin_dir)"
STAGE_DIR="/srv/tmp/backup_stage"

for cmd in gzip socat sudo time tar; do
    if ! command -v "$cmd" &> /dev/null; then
        echo "ERROR: Required program '${cmd}' is missing." >&2
        exit 1
    fi
done

echo "=== Creating local backup ==="
sudo rm -rf "${STAGE_DIR}"
sudo mkdir -p "${STAGE_DIR}"

time sudo "${MARIADB_BIN_DIR}/mariadb-backup" --backup \
  --target-dir="${STAGE_DIR}" \
  --user=root \
  --open-files-limit=65535

echo "=== Preparing the backup ==="
time sudo "${MARIADB_BIN_DIR}/mariadb-backup" --prepare \
  --target-dir="${STAGE_DIR}"

echo "=== Streaming prepared backup to replica (${REPLICA_HOST}:${TRANSFER_PORT}) ==="
time sudo bash -c "tar -C ${STAGE_DIR} -cf - . | gzip -1 | socat -u - TCP:${REPLICA_HOST}:${TRANSFER_PORT}"

echo "=== Cleaning up staging directory ==="
sudo rm -rf "${STAGE_DIR}"
echo "=== Stream transmission completed ==="
