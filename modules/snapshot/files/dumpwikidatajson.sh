#!/bin/bash
#
# Generate a json dump for Wikidata and remove old ones.
# To be run weekly.
#
# @author Marius Hoch < hoo@online.de >

configfile="/srv/dumps/confs/wikidump.conf"

today=`date +'%Y%m%d'`
apacheDir=`awk -Fdir= '/^dir=/ { print $2 }' "$configfile"`
targetDirBase=`awk -Fpublic= '/^public=/ { print $2 }' "$configfile"`/other/wikibase/wikidatawiki
targetDir=$targetDirBase/$today
legacyDirectory=`awk -Fpublic= '/^public=/ { print $2 }' "$configfile"`/other/wikidata
tempDir=`awk -Ftemp= '/^temp=/ { print $2 }' "$configfile"`
daysToKeep=70

if [ -z "$targetDirBase" ]; then
	echo "Empty \$targetDirBase"
	exit 1
fi

# Create the dir for the day: This may or may not already exist, we don't care
mkdir -p $targetDir

multiversionscript="${apacheDir}/multiversion/MWScript.php"

filename=wikidata-$today-all
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
cutOff=$(( `date +%s` - `expr $daysToKeep + 1` * 24 * 3600)) # Timestamp from $daysToKeep + 1 days ago
foldersToDelete=`ls -d -r $targetDirBase/*` # $targetDirBase is known to be non-empty
for folder in $foldersToDelete; do
	# Try to get the unix time from the folder name, if this fails we'll just
	# keep the folder (as it's not a valid date, thus hasn't been created by this script).
	creationTime=$(date --utc --date="$(basename $folder)" +%s 2>/dev/null)
	if [ -n "$creationTime" ] && [ "$cutOff" -gt "$creationTime" ]; then
		rm -rf $folder
	fi
done

# Legacy directory (with legacy naming scheme)
ln -s $targetFile "$legacyDirectory/$today.json"
find $legacyDirectory -name '*.json.gz' -mtime +`expr $daysToKeep + 1` -delete

# Remove old logs (keep 5 => last 35 days)
find /var/log/wikidatadump/ -name 'dumpwikidatajson-*-*.log' -mtime +36 -delete
