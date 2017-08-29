#!/bin/bash

numthreads=16
backupdir="/srv/backups"
shards="s2 s3 s5 s6 s7 x1"
host="localhost"
rowsmax=20000000

mkdir -p "$backupdir"
chmod go-rwx "$backupdir"

# TODO: $backupdir sanitization
find "$backupdir" -mtime +14 -type f -delete
find "$backupdir" -mtime +14 -type d -exec rmdir '{}' ';'

for backup_shard in $shards; do
    /usr/bin/mydumper --compress --host="$host" --threads="$numthreads" --user="`whoami`" --socket="/run/mysqld/mysqld.$backup_shard.sock" --triggers --routines --events --rows="$rowsmax" --logfile="$backupdir/dump.$backup_shard.log" --outputdir="$backupdir/$backup_shard.`date +%Y%m%d%H%M%S`";
done

# TODO: s3 packaging
