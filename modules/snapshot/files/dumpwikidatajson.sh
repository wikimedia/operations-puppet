#!/bin/bash
#
# Generate a json dump for Wikidata and remove old ones.
#
# Marius Hoch < hoo@online.de >

. /usr/local/bin/wikidatadumps-shared.sh

filename=wikidata-`date +'%Y%m%d'`-all
targetFile=$targetDir/$filename.json.gz

i=0
shards=4

while [ $i -lt $shards ]; do
	php $multiversionscript extensions/Wikidata/extensions/Wikibase/repo/maintenance/dumpJson.php --wiki wikidatawiki --shard $i --sharding-factor $shards --snippet 2>> /var/log/wikidatadump/dumpwikidatajson-$filename-$i.log | gzip > $tempDir/wikidataJson.$i.gz &
	let i++
done

wait

# Open the json list
echo '[' | gzip -f > $targetFile

i=0
while [ $i -lt $shards ]; do
	cat $tempDir/wikidataJson.$i.gz >> $targetFile
	rm $tempDir/wikidataJson.$i.gz
	let i++
	if [ $i -lt $shards ]; then
		# Shards don't end with commas so add commas to separate them
		echo ',' | gzip -f >> $targetFile
	fi
done

# Legacy directory (with legacy naming scheme), contains symlinks
legacyDirectory=`awk -Fpublic= '/^public=/ { print $2 }' "$configfile"`/other/wikidata
ln -s $targetFile "$legacyDirectory/`date +'%Y%m%d'`.json"
find $legacyDirectory -name '*.json.gz' -mtime +71 -delete

# Close the json list
echo -e '\n]' | gzip -f >> $targetFile

pruneOldDirectories
pruneOldLogs
