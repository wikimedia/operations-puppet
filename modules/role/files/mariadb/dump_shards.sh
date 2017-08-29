#!/bin/bash

numthreads=16
backupdir="backups"
shards="s2 s3 s5 s6 s7 x1"
host="localhost"
rowsmax=20000000

mkdir -p "/srv/$backupdir"
chmod go-rwx "/srv/$backupdir"

find "/srv/$backupdir" -mtime +14 -type f -delete
find "/srv/$backupdir" -mtime +14 -type d -exec rmdir '{}' ';'

for backup_shard in $shards; do 
    /usr/bin/mydumper --compress --host="$host" --threads="$numthreads" --user="`whoami`" --socket="/run/mysqld/mysqld.$backup_shard.sock" --triggers --routines --events --rows="$rowsmax" --logfile="/srv/$backupdir/dump.$backup_shard.log" --outputdir="/srv/$backupdir/$backup_shard.`date +%Y%m%d%H%M%S`";
done

