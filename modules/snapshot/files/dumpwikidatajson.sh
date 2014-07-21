#!/bin/bash
#
# Generate a json dump for Wikidata and remove old ones.
#
# @author Marius Hoch < hoo@online.de >


configfile="/srv/dumps/confs/wikidump.conf"

apacheDir=`egrep "^dir=" "$configfile" | mawk -Fdir= '{ print $2 }'`
targetDir=`egrep "^public=" "$configfile" | mawk -Fpublic= '{ print $2 }'`/other/wikidata
tempDir=`egrep "^temp=" "$configfile" | mawk -Ftemp= '{ print $2 }'`

multiversionscript="${apacheDir}/multiversion/MWScript.php"

targetFile=$targetDir/`date +'%Y%m%d'`.json.gz

i=0
shards=4

while [ $i -lt $shards ]; do
	php $multiversionscript extensions/Wikidata/extensions/Wikibase/repo/maintenance/dumpJson.php --wiki wikidatawiki --shard $i --sharding-factor $shards --snippet | gzip > $tempDir/wikidataJson.$i.gz &
	let i++
done

wait

i=0

echo '[' | gzip -f > $targetFile

while [ $i -lt $shards ]; do
	cat $tempDir/wikidataJson.$i.gz >> $targetFile
	rm $tempDir/wikidataJson.$i.gz
	let i++
	if [ $i -lt $shards ]; then
		# Shards don't end with commas so add commas to separate them
		echo -n ',' | gzip -f >> $targetFile
	fi
done

echo ']' | gzip -f >> $targetFile

# Remove dumps we no longer need (keep 10)
filesToDelete=`ls -r $targetDir/20*.gz | tail -n +11`
if [ -n "$filesToDelete" ]; then
	rm $filesToDelete
fi
