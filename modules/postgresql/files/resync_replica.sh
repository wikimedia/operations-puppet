#!/bin/bash

set -e
set -u

POSTGRES_VERSION=$(/usr/share/postgresql-common/supported-versions | tail -1)

function show_help() {
    echo "Resync the local replica to the configured Postgres primary. Removes all local data"
    echo "Usage: ${0##*/} pg_version"
}

function parse_args() {
    if [ -n "${1:-}" ]; then
        POSTGRES_VERSION="$1"
        echo "Setting postgres version to $POSTGRES_VERSION"
    fi
}

parse_args "$@"
POSTGRES_PATH=$(pg_conftool "$POSTGRES_VERSION" main show data_directory -s)

if [ ! -d "$POSTGRES_PATH" ]; then
    echo "Postgres data dir not found at $POSTGRES_PATH"
    exit 2
fi

echo "Stopping postgres"
service postgresql stop

rm -R "$POSTGRES_PATH"
install --directory --mode 700 --owner postgres --group postgres "$POSTGRES_PATH"

PGPASSFILE="/etc/postgresql/${POSTGRES_VERSION}/main/.pgpass"
PG_HOST=$(cut -f1 -d: < "$PGPASSFILE")

# -R will cause pg_basebackup to write out a new recovery.conf -
# without this file, postgres will start up as a non-replica and the
# host will need to be re-synced. Puppet will overwrite this file on a
# later run but it will more or less contain the same information
BACKUP_COMMAND="PGPASSFILE=\"$PGPASSFILE\" pg_basebackup -R -X stream -D \"$POSTGRES_PATH\" -U replication -w -h \"$PG_HOST\""

echo "Starting backup from primary - this will take a while"
su postgres --login --command "$BACKUP_COMMAND"
echo "Backup complete"

echo "Resync complete - restarting postgres service"

service postgresql restart
