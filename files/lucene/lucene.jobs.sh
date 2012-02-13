#!/bin/bash

base=/a/search
confs="$base/conf"
import="$base/indexes/import" # here the importer builds the index
index="$base/indexes/index" # here indexer keeps it's copy
dumps="$base/dumps"
ls2="$base/lucene-search"

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

	slave=`php $confs/common/php/maintenance/getSlaveServer.php $dbname`
	echo "Dumping $dbname..."
	php $confs/common/multiversion/MWScript.php dumpBackup.php $dbname --current > $dumpfile && 
	import-file $dumpfile $dbname &&
	(
	  if [ -e $import ]; then
	    echo "Imported $dbname"
	  else
	    echo "Failed $dbname"
	  fi
	)
}

function indexer-cron {
	cd $ls2 && 
	java -Xmx8000m -cp LuceneSearch.jar org.wikimedia.lsearch.spell.SuggestBuilder -l >> $base/log/log-spell 2>&1 &

	cd $ls2 &&
	java -Xmx4000m -cp LuceneSearch.jar org.wikimedia.lsearch.related.RelatedBuilder -l >> $base/log/log-related 2>&1 &
}

function import-private-cron {
	# Import all dbs in the cluster
	for dbname in `<$conf/common/private.dblist`;do
        	import-db $dbname
	done

	for dbname in `<$conf/common/fishbowl.dblist`;do
        	import-db $dbname
	done
}

function build-prefix {
	cd $ls2 &&
	java -cp LuceneSearch.jar org.wikimedia.lsearch.util.Snapshot -pre -p *.prefix.pre >> $base/log/log-prefix 2>&1 &&
	java -Xmx4000m -cp LuceneSearch.jar org.wikimedia.lsearch.prefix.PrefixIndexBuilder -l -s >> $base/log/log-prefix 2>&1 &
}

if [ -z "$1" ] ; then
	echo "$0: Requires an argument"
	exit 42
fi

if [ "$1" = "snapshot" ] ; then
	curl http://localhost:8321/snapshot
elif [ "$1" = "snapshot-precursors" ] ; then
	curl "http://localhost:8321/snapshotPrecursors?p=*.spell.pre"
elif [ "$1" = "indexer-cron" ] ; then
	indexer-cron
elif [ "$1" = "import-private-cron" ] ; then
	import-private-cron
elif [ "$1" = "import-broken-cron" ] ; then
	import-db dewikisource >> $base/log/log-dewikisource 2>&1 &
elif [ "$1" = "build-prefix" ] ; then
	build-prefix
else
	echo "$0: argument not recognized"
	exit 1
fi
