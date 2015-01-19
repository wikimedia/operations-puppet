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

filename=`date +'%Y%m%d'`
targetFile=$targetDir/$filename.json.gz

i=0
shards=4

while [ $i -lt $shards ]; do
	php $multiversionscript extensions/Wikidata/extensions/Wikibase/repo/maintenance/dumpJson.php --wiki wikidatawiki --shard $i --sharding-factor $shards --snippet 2>> /var/log/wikidatadump/dumpwikidatajson-$filename-$i.log | gzip > $tempDir/wikidataJson.$i.gz &
	let i++
done

wait

i=0

# Open the json list
echo '[' | gzip -f > $targetFile

while [ $i -lt $shards ]; do
	cat $tempDir/wikidataJson.$i.gz >> $targetFile
	rm $tempDir/wikidataJson.$i.gz
	let i++
	if [ $i -lt $shards ]; then
		# Shards don't end with commas so add commas to separate them
		echo ',' | gzip -f >> $targetFile
	fi
done

# Close the json list
echo -e '\n]' | gzip -f >> $targetFile

# Remove dumps we no longer need (keep 10 => last 70 days)
find $targetDir -name '20*.gz' -mtime +71 -delete

# Remove old logs (keep 5 => last 35 days)
find /var/log/wikidatadump/ -name 'dumpwikidatajson-*-*.log' -mtime +36 -delete
