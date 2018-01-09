#!/bin/bash

NUMTHREADS=${NUMTHREADS:-16}
BACKUPDIR=${BACKUPDIR:-"/srv/backups"}
# FIXME: All shards, including misc
SHARDS=${SHARDS:-"s2 s3 s5 s6 s7 s8 x1"}
SERVER=${SERVER:-"localhost"}
ROWSMAX=${ROWSMAX:-20000000}

mkdir -p "${BACKUPDIR}"
# Make sure we got a very specific mode in our directory
chmod 0700 "${BACKUPDIR}"

# TODO: $BACKUPDIR sanitization
find "${BACKUPDIR}" -mtime +14 -type f -delete
find "${BACKUPDIR}" -mtime +14 -type d -exec rmdir '{}' ';'

DATE=$(date "+%Y%m%d%H%M%S")
# Overwrite/define USER since it may not be defined or may not be set correctly
USER=$(whoami)

# TODO: Check the database (local or remote) we are connectiong to is available

# Sanitize IFS
OLD_IFS=$IFS
IFS=' '
# $USER will always contain the current euid
for shard in $SHARDS; do
    /usr/bin/mydumper \
        --compress \
        --events \
        --triggers \
        --host="${SERVER}" \
        --logfile="${BACKUPDIR}/dump.${shard}.log" \
        --outputdir="${BACKUPDIR}/${shard}.${DATE}" \
        --routines \
        --rows="${ROWSMAX}" \
        --socket="/run/mysqld/mysqld.${shard}.sock" \
        --threads="${NUMTHREADS}" \
        --user="${USER}"
done
# Restore IFS
IFS=$OLD_IFS

# TODO: s3 packaging
