#!/bin/bash
vslow_host=dbstore1002.eqiad.wmnet
vslow_port=3306
target_host=db1069.eqiad.wmnet
target_port=3311
query="SELECT count(*) as watchers, wl_namespace, wl_title FROM watchlist GROUP BY wl_namespace, wl_title HAVING watchers > 29"
table=watchlist_count
lock_dir=/tmp/lock-generate-labs-table
tmp_dir=/tmp/lock-generate-labs-table

if mkdir $lock_dir; then
  echo "Locking succeeded" >&2
else
  echo "Lock failed - exit" >&2
  exit 1
fi

for shard in 1 2 3 4 5 6 7; do
    sort /srv/mediawiki/dblists/private.dblist \
/srv/mediawiki/dblists/private.dblist /srv/mediawiki/dblists/s${shard}.dblist \
| uniq -u | \
    while read db; do
#        echo "Creating table $db.$table..."
#        mysql -h $target_host -P 331${shard} $db -e "CREATE TABLE IF NOT EXISTS watchlist_count (watchers bigint NOT NULL DEFAULT '0', wl_namespace int NOT NULL DEFAULT '0', wl_title varbinary(255) NOT NULL DEFAULT '', PRIMARY KEY (wl_namespace, wl_title), KEY watchers (watchers))"
        echo "Generating table $db.$table..."
        mysql -BN -A -h $vslow_host -P $vslow_port $db -e "$query" \
> ${tmp_dir}/${db}.${table}.txt
        echo "Saving table to $target_host..."
        mysql -h $target_host -P 331${shard} $db -e "TRUNCATE TABLE ${table}" &&
        mysql -h $target_host -P 331${shard} $db --local-infile -e \
"LOAD DATA LOCAL INFILE '${tmp_dir}/${db}.${table}.txt' INTO TABLE ${table}" &&
        rm ${tmp_dir}/${db}.${table}.txt
    done
done

rmdir ${lock_dir}
