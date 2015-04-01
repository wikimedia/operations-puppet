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

# Close the json list
echo -e '\n]' | gzip -f >> $targetFile

# Remove dump-folders we no longer need (keep $daysToKeep days)
cutOff=$(expr `date +%s` - `expr $daysToKeep + 1` * 24 * 3600) # Keep folders younger than this (unix time)
foldersToDelete=`ls -d -r $targetDirBase/*` # $targetDirBase is known to be non-empty
for folder in $foldersToDelete; do
	# Try to get the unix time from the folder name, if this fails we'll just
	# keep the folder (as it's not a valid date).
	creationTime=$(date --utc --date="$(basename $folder)" +%s 2>/dev/null)
	if [ -n "$creationTime" ] && [ "$cutOff" -lt "$creationTime" ]; then
		rm -rf $folder
	fi
done

# Legacy directory (with legacy naming scheme), contains symlinks
legacyDirectory=`awk -Fpublic= '/^public=/ { print $2 }' "$configfile"`/other/wikidata
ln -s $targetFile "$legacyDirectory/`date +'%Y%m%d'`.json"
find $legacyDirectory -name '*.json.gz' -mtime +`expr $daysToKeep + 1` -delete

pruneOldDirectories
pruneOldLogs
