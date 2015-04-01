#!/bin/bash
#
# Generate a json dump for Wikidata and remove old ones.
#
# @author Marius Hoch < hoo@online.de >

configfile="/srv/dumps/confs/wikidump.conf"

apacheDir=`awk -Fdir= '/^dir=/ { print $2 }' "$configfile"`
targetDirBase=`awk -Fpublic= '/^public=/ { print $2 }' "$configfile"`/other/wikibase/wikidatawiki
targetDir=$targetDirBase/`date +'%Y%m%d'`
legacyDirectory=`awk -Fpublic= '/^public=/ { print $2 }' "$configfile"`/other/wikidata
tempDir=`awk -Ftemp= '/^temp=/ { print $2 }' "$configfile"`

if [ -z "$targetDirBase" ]; then
	echo "Empty targetDirBase";
	exit 1
fi

# Create the dir for the day: This may or may not already exist, we don't care
mkdir $targetDir 2> /dev/null

multiversionscript="${apacheDir}/multiversion/MWScript.php"

filename=wikidata-`date +'%Y%m%d'`-all
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

# Remove dump-folders we no longer need (keep 10 => last 70 days)
foldersToDelete=`ls -d -r $targetDirBase/* | tail -n +11` # $targetDirBase is known to be non-empty (per the check above)
if [ -n "$foldersToDelete" ]; then
	rm -rf $foldersToDelete
fi

# Legacy directory (with legacy naming scheme)
ln -s $targetFile "$legacyDirectory/`date +'%Y%m%d'`.json"
find $legacyDirectory -name '*.json.gz' -mtime +70 -delete

# Remove old logs (keep 5 => last 35 days)
find /var/log/wikidatadump/ -name 'dumpwikidatajson-*-*.log' -mtime +36 -delete
