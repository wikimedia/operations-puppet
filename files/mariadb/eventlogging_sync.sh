#!/bin/bash

# Event Logging tables hold time-series data which is not updated, but may be purged.
# Every table includes an auto-inc id, a uuid, and a timestamp. The INSERT stream
# does not currently take advantage of bulk insert batching which often leads to
# replication lag. Adding DELETE into the mix makes it extra painful.
#
# This script sychronizes a slave using bulk inserts with mysqldump where id > N, and
# purges old data with throttled bulk deletes where id < N order by id limit M.
# Useful for creating a new slave, syncing a broken one, or replacing replication
# with a cron job.

while true; do
## execute endlessly in an infinite loop


db='log'
ls="regexp '^[A-Z0-9].*[0-9]+$'"
mhost='m4-master.eqiad.wmnet'
shost="localhost"

slave="mysql -h $shost --compress --skip-column-names"
master="mysql -h $mhost --compress --skip-column-names"
dump="mysqldump -h $mhost --skip-opt --single-transaction --quick --skip-triggers"
dumpdata="$dump --no-create-info --insert-ignore --extended-insert --compress --hex-blob"
querytables="select table_name from information_schema.tables where table_schema = '$db' and table_name"
# select this many rows per table at a time
batch_size=1000

script=$(basename ${BASH_SOURCE})
# Multi-execution is controlled by init.d
#if [ $(ps ax | grep $script | grep -v grep | wc -l) -gt 2 ]; then
#    echo "duplicate process" 1>&2
#    exit 1
#fi

set -e

for table in $($master $db -e "$querytables $ls"); do

    echo -n "`date` $shost $table"

    if [ $($slave $db -e "$querytables = '$table'" | wc -l) -eq 0 ]; then
        echo -n ", create"
        $dump --no-data $db $table | $slave $db
    fi

    #id=$($master $db -e "select min(id) from \`$table\`")

    #if [ ! $id = "NULL" ]; then
        #echo -n ", purge < $id"
        #$slave $db -e "delete from \`$table\` where id < $id order by id limit 100000"
    #fi

    ts=$($slave $db -e "select ifnull(max(timestamp),0) from \`$table\`")

    echo -n " >= $ts"
    # mysqldump has overhead with information_schema queries, so do a quick check for a noop
    if [ ! $($master $db -e "select ifnull(max(timestamp),0) from \`$table\`") = $ts ]; then
        echo -n " (rows!)"
        # ORDER BY 1 orders by the first field, which should be the PK.
        # Have to do this because we can't use --order-by-primary with a custom
        # LIMIT, and not all tables have the same field name as the id.
        # (I've seen uuid and id.)
        $dumpdata --insert-ignore --where="timestamp >= '$ts' ORDER BY 1 LIMIT $batch_size" $db "$table" | $slave $db
        #$dumpdata --insert-ignore --where="timestamp >= '$ts'" $db "$table" >tmp/$table.sql
    else
        echo -n " (nothing)"
    fi

    echo " ok"

done

#echo "Sleeping for 10 seconds before the next batch..."
#sleep 10

## infinite loop
done
