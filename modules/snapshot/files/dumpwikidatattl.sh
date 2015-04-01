#!/bin/bash
#
# Generate a json dump for Wikidata and remove old ones.
#
# Marius Hoch < hoo@online.de >

. /usr/local/bin/wikidatadumps-shared.sh

filename=wikidata-$today-all-BETA
targetFile=$targetDir/$filename.ttl.gz

i=0
shards=4

while [ $i -lt $shards ]; do
	php $multiversionscript extensions/Wikidata/extensions/Wikibase/repo/maintenance/dumpRdf.php --wiki wikidatawiki --shard $i --sharding-factor $shards --format ttl 2>> /var/log/wikidatadump/dumpwikidatattl-$filename-$i.log | gzip > $tempDir/wikidataTTL.$i.gz &
	let i++
done

wait

i=0
while [ $i -lt $shards ]; do
	cat $tempDir/wikidataTTL.$i.gz >> $targetFile
	rm $tempDir/wikidataTTL.$i.gz
	let i++
done

pruneOldDirectories
pruneOldLogs
