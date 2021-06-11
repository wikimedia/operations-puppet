#!/bin/bash

set -e

POSTGRES_VERSION=9.6

function show_help() {
    echo "Resync the local replica to the configured Postgres primary. Removes all local data"
    echo "Usage: ${0##*/} pg_version"
}

function parse_args() {
    if [ -z "$1" ]; then
        POSTGRES_VERSION="$1"
        echo "Setting postgres version to $POSTGRES_VERSION"
    fi
}

parse_args "$@"
POSTGRES_PATH="/srv/postgresql/$POSTGRES_VERSION/main"

if [ ! -d "$POSTGRES_PATH" ]; then
    echo "Postgres data dir not found at $POSTGRES_PATH"
    exit 2
fi

echo "Stopping postgres"
service postgresql stop

rm -R "$POSTGRES_PATH"
mkdir -p "$POSTGRES_PATH"

# pg_basebackup will use PGPASSFILE for credentials
# shellcheck disable=SC2034
PGPASSFILE="/etc/postgresql/${POSTGRES_VERSION}/main/.pgpass"
PG_HOST=$(cat $PGPASSFILE | cut -f1 -d:)

# -R will cause pg_basebackup to write out a new recovery.conf -
# without this file, postgres will start up as a non-replica and the
# host will need to be re-synced. Puppet will overwrite this file on a
# later run but it will more or less contain the same information
echo "Starting backup from primary - this will take a while"
/usr/bin/pg_basebackup -R -X stream -D "$POSTGRES_PATH" -U replication -w -h "$PG_HOST"
echo "Backup complete"

chown -R postgres:postgres "$POSTGRES_PATH"

echo "Resync complete - postgres can now be started"
