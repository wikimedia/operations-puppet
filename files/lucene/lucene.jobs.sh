#!/bin/bash

base=/a/search
confs="$base/conf"
import="$base/indexes/import" # here the importer builds the index
index="$base/indexes/index" # here indexer keeps it's copy
dumps="$base/dumps"
ls2="$base/lucene-search"

MWinstall="/srv/mediawiki"
dblist="$confs/all.dblist"

JAVA_OPTS_IMPORTER='-Xms128m -Xmx2000m'
JAVA_OPTS_PREFIXINDEXBUILDER='-Xmx4000m'
JAVA_OPTS_RELATEDBUILDER='-Xmx4000m'
JAVA_OPTS_SUGGESTBUILDER='-Xmx8000m'

# load configuration file maintained by puppet
if [ -s "$confs/lucene.jobs.conf" ]; then
	. "$confs/lucene.jobs.conf"
fi

# detect realm (production or labs)
WMF_REALM='production'
if [ -f /etc/wikimedia-realm ]
then
	WMF_REALM=`cat /etc/wikimedia-realm`
fi
# Per realm override
case "$WMF_REALM" in
	'labs')
		dblist="$confs/all-labs.dblist"
	;;
esac

pvtlist="$confs/private.dblist"

function build-new {
	cd $ls2
	rm -f $base/indexes/status/$1
	java -cp LuceneSearch.jar org.wikimedia.lsearch.oai.IncrementalUpdater $1
	java -cp LuceneSearch.jar org.wikimedia.lsearch.util.Snapshot -p ${1}.links
	java -cp LuceneSearch.jar org.wikimedia.lsearch.related.RelatedBuilder $1
	java -cp LuceneSearch.jar org.wikimedia.lsearch.oai.IncrementalUpdater $1
	java -cp LuceneSearch.jar org.wikimedia.lsearch.util.Snapshot -p $1
	java -cp LuceneSearch.jar org.wikimedia.lsearch.util.Snapshot -p ${1}.hl
	java -cp LuceneSearch.jar org.wikimedia.lsearch.util.Snapshot -pre -p ${1}.spell.pre
	java -cp LuceneSearch.jar org.wikimedia.lsearch.spell.SuggestBuilder -s $1
	java -cp LuceneSearch.jar org.wikimedia.lsearch.util.Snapshot -p ${1}.spell
	java -cp LuceneSearch.jar org.wikimedia.lsearch.prefix.PrefixIndexBuilder $1
}

function import-file {
	echo "Importing $2 ..."
	# Syntax: import-file <xmldump> <dbname>
	cd $ls2 &&
	java $JAVA_OPTS_IMPORTER -cp $ls2/LuceneSearch.jar org.wikimedia.lsearch.importer.BuildAll $1 $2
}

function import-db {
	dbname="$1"
	dumpfile="$dumps/dump-$dbname.xml"
	timestamp=`date -u +%Y-%m-%d`

	# not going to compute this param as it's broken in dumpBackup.php
	#slave=`php $MWinstall/multiversion/MWScript.php getSlaveServer.php $dbname`

	echo "Dumping $dbname..."
	php $MWinstall/multiversion/MWScript.php dumpBackup.php $dbname --current > $dumpfile &&
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
	for dbname in `<$confs/private.dblist`;do
		import-db $dbname >> $base/log/log-private 2>&1
	done

	for dbname in `<$confs/fishbowl.dblist`;do
		import-db $dbname >> $base/log/log-private 2>&1
	done
}

function indexer-cron {
	cd $ls2 &&
	java $JAVA_OPTS_SUGGESTBUILDER -cp LuceneSearch.jar org.wikimedia.lsearch.spell.SuggestBuilder -l >> $base/log/log-spell 2>&1 &

	cd $ls2 &&
	java $JAVA_OPTS_RELATEDBUILDER -cp LuceneSearch.jar org.wikimedia.lsearch.related.RelatedBuilder -l >> $base/log/log-related 2>&1 &
}

function build-prefix {
	cd $ls2 &&
	java -cp LuceneSearch.jar org.wikimedia.lsearch.util.Snapshot -pre -p *.prefix.pre >> $base/log/log-prefix 2>&1 &&
	java $JAVA_OPTS_PREFIXINDEXBUILDER -cp LuceneSearch.jar org.wikimedia.lsearch.prefix.PrefixIndexBuilder -l -s >> $base/log/log-prefix 2>&1 &
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
	curl "http://localhost:8321/snapshotPrecursors?p=*.spell.pre" >> $base/log/log-snapshot-pre 2>&1
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
elif [ "$1" = "build-new" ] && [ "$2" ] ; then
	build-new $2
elif [ "$1" = "import-db" ] && [ "$2" ] ; then
        import-db $2
else
	echo "$0: argument not recognized"
	exit 1
fi
