#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# WARNING: This file is managed by Puppet.
# Source: modules/beta/files/receive_replica.sh
set -euo pipefail

usage() {
    cat >&2 <<EOF
Usage: $0 <master_hostname>

Provision this host as a MariaDB replica by receiving a prepared data stream,
running dictionary upgrade steps, and starting GTID-based replication from the
specified master host.
EOF
    exit 1
}

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
    usage
fi

MASTER_HOST="$1"
REPL_USER="repl"
MARIADB_BIN_DIR="$(detect_mariadb_bin_dir)"
DATA_DIR="/srv/sqldata"
TRANSFER_PORT=1234
PUPPET_REASON="Mariadb replica provisioning"
MYSQL_SOCKET_DIR="/run/mysqld"
MYSQL_SOCKET="${MYSQL_SOCKET_DIR}/mysqld.sock"

for cmd in getent socat awk sudo time tar read; do
    if ! command -v "$cmd" &> /dev/null; then
        echo2 "ERROR: Required program '${cmd}' is missing."
        exit 1
    fi
done

echo "WARNING: This operation is destructive."
echo "It will stop MariaDB and permanently remove all data under ${DATA_DIR}."
read -r -p "Type 'yes' to continue: " CONFIRM_DESTRUCTIVE
if [ "${CONFIRM_DESTRUCTIVE}" != "yes" ]; then
    echo2 "Aborting at user request."
    exit 1
fi

read -rs -p "Enter replication password for user '${REPL_USER}': " REPL_PASS
echo ""

if [ -z "${REPL_PASS}" ]; then
    echo2 "ERROR: Replicaion password cannot be empty."
    exit 1
fi

echo "=== Disabling Puppet  ==="
sudo disable-puppet "${PUPPET_REASON}"

trap 'echo "=== Error occurred. Re-enabling Puppet ==="; sudo enable-puppet "${PUPPET_REASON}"' ERR

MASTER_IP="$(getent ahostsv4 "${MASTER_HOST}" | awk 'NR==1 {print $1}')"
if [ -z "${MASTER_IP}" ]; then
    echo2 "ERROR: Failed to determine IP address of ${MASTER_HOST}"
    exit 1
fi

echo "=== Stopping MariaDB and wiping data directory ==="
sudo systemctl stop mariadb
sudo rm -rf "${DATA_DIR}"
sudo mkdir -p "${DATA_DIR}"
sudo chown mysql:mysql "${DATA_DIR}"

echo "=== Listening for data stream on port ${TRANSFER_PORT} ==="
time sudo bash -c "socat -u TCP-LISTEN:${TRANSFER_PORT},reuseaddr - | tar -C ${DATA_DIR} -xzf -"

echo "=== Setting ownership on extracted data ==="
sudo chown -R mysql:mysql "${DATA_DIR}"

echo "=== Starting MariaDB ==="
sudo mkdir -p "${MYSQL_SOCKET_DIR}"
sudo chown mysql:mysql "${MYSQL_SOCKET_DIR}"

sudo -b "${MARIADB_BIN_DIR}/mariadbd-safe" --skip-grant-tables --skip-networking --socket="${MYSQL_SOCKET}"

echo "Waiting for MariaDB service to initialize..."
sleep 6

echo "=== Running MariaDB upgrade ==="
sudo "${MARIADB_BIN_DIR}/mariadb-upgrade" --socket="${MYSQL_SOCKET}"

echo "=== Restarting MariaDB ==="
sudo "${MARIADB_BIN_DIR}/mariadb-admin" --socket="${MYSQL_SOCKET}" shutdown
sleep 3

sudo systemctl start mariadb

echo "=== Initializing replication ==="
REPL_GTID=$(sudo awk '{print $3}' "${DATA_DIR}/xtrabackup_binlog_info")

if [ -z "${REPL_GTID}" ]; then
    echo2 "ERROR: Could not parse GTID from backup metadata!"
    exit 1
fi

sudo "${MARIADB_BIN_DIR}/mariadb" -u root -e "
  SET GLOBAL gtid_slave_pos = '${REPL_GTID}';
  CHANGE MASTER TO
    MASTER_HOST='${MASTER_IP}',
    MASTER_USER='${REPL_USER}',
    MASTER_PASSWORD='${REPL_PASS}',
    MASTER_PORT=3306,
    MASTER_USE_GTID=slave_pos;
  START REPLICA;
"

echo "=== Success! Re-enabling Puppet ==="
trap - ERR
sudo enable-puppet "${PUPPET_REASON}"

echo "=== Finalizing: Checking replication status ==="
sudo "${MARIADB_BIN_DIR}/mariadb" -u root -e "SHOW REPLICA STATUS\G" | grep -E "Running:|Behind_Master"
