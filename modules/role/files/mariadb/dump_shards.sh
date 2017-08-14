#!/bin/bash

numthreads=16
backupdir=backups
shards="s1 s4 s5 s2 s6 s7 s3 x1"
rowsmax=100000000

[ -z "$backupdir" ] && { echo "backupdir variable is empty"; exit 1 }
[ "$backupdir" == "/" ] && { echo "backupdir variable cannot be the root directory"; exit 1 }
[[ "$HOST" =~ ^sqldata.* ]] && { echo "backupdir variable cannot start with sqldata"; exit 1 }

mkdir -p "/srv/$backupdir"
chmod go-rwx "/srv/$backupdir"

find "/srv/$backupdir" -mtime +14 -type f -delete
find "/srv/$backupdir" -mtime +14 -type d -exec rmdir \{\} \;

# stopping all replication activity to save iops
for stop_shard in $shards; do 
    /usr/local/bin/mysql --socket="/run/mysqld/mysqld.$stop_shard.sock" -e "STOP SLAVE"
done

for backup_shard in $shards; do

    /usr/bin/mydumper/mydumper --compress --host=localhost --threads="$numthreads" --user="`whoami`" --socket="/run/mysqld/mysqld.$backup_shard.sock" --triggers --routines --events --rows="$rowsmax" --logfile="/srv/$backupdir/dump.$shard.log" --outputdir="/srv/$backupdir/$backup_shard.`date +%Y%m%d%H%M%S`"
done

# Restarting replication
for start_shard in $shards; do
    /usr/local/bin/mysql --socket="/run/mysqld/mysqld.$start_shard.sock" -e "START SLAVE"
done
