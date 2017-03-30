#!/bin/bash

# Event Logging tables hold time-series data which is not updated, but may be purged.
# Every table includes an auto-inc id, a uuid, and a timestamp. The INSERT stream
# does not currently take advantage of bulk insert batching which often leads to
# replication lag. Adding DELETE into the mix makes it extra painful.
#
# This script sychronizes a slave using bulk inserts with mysqldump where id (or timestamp, if no
# id field exists) > N, and purges old data with throttled bulk deletes where id < N order by id
# limit M.  Useful for creating a new slave, syncing a broken one, or replacing replication
# with a cron job.


script_name=$(basename $0)

function usage {
    echo "
${script_name} [-n] [-b <batch-size>] [-D <cutoff-days>] [-d <database>] <master-host> [<slave-host>]

OPTIONS:
  -h  Print this usage message
  -n  Dry run. Only print the dump command that will be run, don't actually dump from master into slave.
  -b  Batch replicate this many rows at a time.  Default: 1000
  -d  Database name.  Default: log
  -D  Don't replicate tables if they don't have events more recent than than -D days ago.

DESCRIPTION:
  Checks all eventlogging tables on <master-host>, and looks for those tables in <slave-host>
  If <master-host> has any records with a larger auto increment `id` (or `timestamp`) than
  <slave-host>, then those records are mysqldumped into <slave-host> <batch-size> records at a time.

  <slave-host> defaults to localhost.
"

exit 0
}

# select this many rows per table at a time
batch_size=1000
database=log
slave_host=localhost
dry_run=0
cutoff_days=0

while getopts "hnvb:d:D:" opt; do
    case "$opt" in
    h)
        usage
        ;;
    b)  batch_size=$OPTARG
        ;;
    d)
        database=$OPTARG
        ;;
    D)
        cutoff_days=$OPTARG
        ;;
    n)
        dry_run=1
        ;;
    esac
done

shift $((OPTIND-1))


master_host="${1}"
[ -z "${master_host}" ] && echo "ERROR: Must specify <master-host>" && usage
shift

# Last arg will be slave_host if given, otherwise use localhost.
[ -n "${1}" ] && slave_host="${1}"



table_regex="regexp '^[A-Z0-9].*[0-9]+$'"

slave="mysql -h $slave_host --compress --skip-column-names --skip-ssl"
master="mysql -h $master_host --compress --skip-column-names --skip-ssl"

dump_opts="--skip-ssl --skip-opt --single-transaction --quick --skip-triggers"
dump_schema="mysqldump -h $master_host $dump_opts --no-data"
dump_data="mysqldump -h $master_host $dump_opts --no-create-info --insert-ignore --extended-insert --compress --hex-blob"

tables_query="select table_name from information_schema.tables where table_schema = '$database'"

# Add and table_name = $table at the end of this query to use it
has_id_column_query="select count(*) from information_schema.columns where table_schema = '$database' and column_name = 'id'"

set -e

# Execute endlessly in an infinite loop.
while true; do

    for table in $($master $database -e "$tables_query and table_name $table_regex order by rand()"); do

        echo -n "$(date +"%Y-%m-%dT%H:%M:%S") $slave_host $table"

        # If no new events for this table since cutoff_days ago, don't attempt to replicate.
        if [ $cutoff_days -ne 0 ]; then
            cutoff_timestamp=$(date --date="$cutoff_days days ago" +'%Y%m%d%H%M%S')

            max_master_timestamp=$($master $database -e "select max(timestamp) from \`$table\` where timestamp >= '$cutoff_timestamp'")
            if [ "${max_master_timestamp}" = "NULL" ]; then
                echo " (no new data on master in last $cutoff_days days, skipping)"
                continue
            fi
        fi

        # If the table does not exist on the slave,
        # then dump the schema from the master to create it.
        if [ $($slave $database -e "$tables_query and table_name = '$table'" | wc -l) -eq 0 ]; then
            echo -n ", create"
            if [  $dry_run -eq 1 ]; then
                echo -n " (dry-run) $dump_schema $database $table | $slave $database"
            else
                $dump_schema $database $table | $slave $database
            fi
        fi

        # # Get the minimum autoincrement id from master table
        # TODO: should we bring this back???
        # id=$($master $database -e "select min(id) from \`$table\`")
        #
        # if [ ! $id = "NULL" ]; then
        #     echo -n ", purge < $id"
        #     $slave $db -e "delete from \`$table\` where id < $id order by id limit 100000"
        # fi

        # replicate by timestamp or id.  id is preferred.
        column='id'
        # If this table does not have an auto-increment id field, then use timestamp instead.
        if [ $($master $database -e "$has_id_column_query and table_name = '$table'") -eq 0 ]; then
            column='timestamp'
        fi

        # Select records from the master where $column > max($column) on the slave,
        # and dump them into the slave.
        max_slave=$($slave $database -e "select ifnull(max($column),0) from \`$table\`")
        max_master=$($master $database -e "select ifnull(max($column),0) from \`$table\`")

        # If no new data on the master, do nothing.
        if [ $max_slave = $max_master ]; then
            echo -n " (nothing)"
        # Else dump $batch_size records from master into the slave.
        else
            echo -n " (rows!)"
            if [  $dry_run -eq 1 ]; then
                echo -n " (dry-run) $dump_data --where=\"$column >= $max_slave ORDER BY $column LIMIT $batch_size\" $database \"$table\" | $slave $database"
            else
                $dump_data --where="id >= $max_slave_id ORDER BY id LIMIT $batch_size" $database "$table" | $slave $database
            fi
        fi

        echo " ok"
    done

    echo "Sleeping for 1 seconds before the next batch..."
    sleep 1

# End infinite loop.
done
