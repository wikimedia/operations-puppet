#!/bin/bash

base=/a/search
confs="$base/conf"
import="$base/indexes/import" # here the importer builds the index
index="$base/indexes/index" # here indexer keeps it's copy
dumps="$base/dumps"
ls2="$base/lucene-search"

MWinstall="/usr/local/apache"
dblist="$MWinstall/common/all.dblist"
pvtlist="$MWinstall/common/private.dblist"

function import-file {
	echo "Importing $2 ..."
	# Syntax: import-file <xmldump> <dbname>
	cd $ls2 && 
	java -Xms128m -Xmx2000m -cp $ls2/LuceneSearch.jar org.wikimedia.lsearch.importer.BuildAll $1 $2
}

function import-db {
	dbname="$1"
	dumpfile="$dumps/dump-$dbname.xml"
	timestamp=`date -u +%Y-%m-%d`

	# not going to compute this param as it's broken in dumpBackup.php
	#slave=`php $MWinstall/common/multiversion/MWScript.php getSlaveServer.php $dbname`

	echo "Dumping $dbname..."
	php $MWinstall/common/multiversion/MWScript.php dumpBackup.php $dbname --current > $dumpfile && 
	import-file $dumpfile $dbname &&
	(
	  if [ -e $import ]; then
	    echo "Imported $dbname"
	  else
	    echo "Failed $dbname"
	  fi
	)
}

function import-private {
	# Import all dbs in the cluster
	for dbname in `<$MWinstall/common/private.dblist`;do
		import-db $dbname >> $base/log/log-private 2>&1
	done

	for dbname in `<$MWinstall/common/fishbowl.dblist`;do
		import-db $dbname >> $base/log/log-private 2>&1
	done
}

function indexer-cron {
	cd $ls2 && 
	java -Xmx8000m -cp LuceneSearch.jar org.wikimedia.lsearch.spell.SuggestBuilder -l >> $base/log/log-spell 2>&1 &

	cd $ls2 &&
	java -Xmx4000m -cp LuceneSearch.jar org.wikimedia.lsearch.related.RelatedBuilder -l >> $base/log/log-related 2>&1 &
}

function build-prefix {
	cd $ls2 &&
	java -cp LuceneSearch.jar org.wikimedia.lsearch.util.Snapshot -pre -p *.prefix.pre >> $base/log/log-prefix 2>&1 &&
	java -Xmx4000m -cp LuceneSearch.jar org.wikimedia.lsearch.prefix.PrefixIndexBuilder -l -s >> $base/log/log-prefix 2>&1 &
}

function inc-updater-start {
	echo "Starting incremental updater ..."

	if [ -n "$2" ]; then
        	timestamp="-dt $2"
	fi

	while true; do
        	cd $ls2 && 
        	java -cp $ls2/LuceneSearch.jar -Djava.rmi.server.hostname=$HOSTNAME org.wikimedia.lsearch.oai.IncrementalUpdater -n -f $dblist -ef $pvtlist -e dewikisource $timestamp -nof /a/search/conf/nooptimize.dblist
        	sleep 15m
	done >> $base/log/log-all 2>&1 &
}

if [ -z "$1" ] ; then
	echo "$0: Requires an argument"
	exit 42
fi

if [ "$1" = "snapshot" ] ; then
	curl http://localhost:8321/snapshot >> $base/log/log-snapshot 2>&1
elif [ "$1" = "snapshot-precursors" ] ; then
	curl "http://localhost:8321/snapshotPrecursors?p=*.spell.pre"
elif [ "$1" = "indexer-cron" ] ; then
	indexer-cron
elif [ "$1" = "import-private" ] ; then
	import-private
elif [ "$1" = "import-broken" ] ; then
	import-db dewikisource >> $base/log/log-dewikisource 2>&1 &
elif [ "$1" = "build-prefix" ] ; then
	build-prefix
elif [ "$1" = "inc-updater-start" ] ; then
	inc-updater-start
else
	echo "$0: argument not recognized"
	exit 1
fi
