#!/bin/bash
#
# Generate an RDF/TTL dump for Wikidata and remove old ones.
#
# @author Marius Hoch < hoo@online.de >
# @author Stas Malyshev < smalyshev@wikimedia.org >

configfile="/srv/dumps/confs/wikidump.conf"

apacheDir=`egrep "^dir=" "$configfile" | mawk -Fdir= '{ print $2 }'`
targetDir=`egrep "^public=" "$configfile" | mawk -Fpublic= '{ print $2 }'`/other/wikidata
tempDir=`egrep "^temp=" "$configfile" | mawk -Ftemp= '{ print $2 }'`

multiversionscript="${apacheDir}/multiversion/MWScript.php"

filename=`date +'%Y%m%d'`
targetFile=$targetDir/$filename.ttl.gz

i=0
shards=4

while [ $i -lt $shards ]; do
	php $multiversionscript extensions/Wikidata/extensions/Wikibase/repo/maintenance/dumpRdf.php --wiki wikidatawiki --shard $i --sharding-factor $shards --format ttl 2>> /var/log/wikidatadump/dumpwikidatattl-$filename-$i.log | gzip > $tempDir/wikidataTTL.$i.gz &
	let i++
done

wait

i=0

# Open the list

while [ $i -lt $shards ]; do
	cat $tempDir/wikidataTTL.$i.gz >> $targetFile
	rm $tempDir/wikidataTTL.$i.gz
	let i++
done

# Remove dumps we no longer need (keep 10 => last 70 days)
find $targetDir -name '20*.gz' -mtime +71 -delete

# Remove old logs (keep 5 => last 35 days)
find /var/log/wikidatadump/ -name 'dumpwikidatattl-*-*.log' -mtime +36 -delete
