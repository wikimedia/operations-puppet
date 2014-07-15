#!/bin/bash
#
# Generate a json dump for Wikidata and remove old ones.
#
# @author Marius Hoch < hoo@online.de >


configfile="/srv/dumps/confs/wikidump.conf"

apacheDir=`egrep "^dir=" "$configfile" | mawk -Fdir= '{ print $2 }'`
targetDir=`egrep "^public=" "$configfile" | mawk -Fdir= '{ print $2 }'`/wikidata
tempDir=`egrep "^temp=" "$configfile" | mawk -Fdir= '{ print $2 }'`

multiversionscript="${apacheDir}/multiversion/MWScript.php"

targetFile=$targetDir/`date +'%Y%m%d'`.json.gz

i=0
shards=4

while [ $i -lt $shards ]; do
	php $multiversionscript extensions/Wikidata/extensions/Wikibase/repo/maintenance/dumpJson.php --wiki wikidatawiki --shard $i --sharding-factor $shards | gzip > $tempDir/wikidataJson.$i.gz &
	let i++
done

wait

i=0

echo '[' | gzip -f > $targetFile

while [ $i -lt $shards ]; do
	cat $tempDir/wikidataJson.$i.gz >> $targetFile
	rm $tempDir/wikidataJson.$i.gz
	let i++
done

echo ']' | gzip -f >> $targetFile


# Remove dumps we no longer need (keep 10)

rm `ls -r $targetDir/20*.gz | tail -n +11`
