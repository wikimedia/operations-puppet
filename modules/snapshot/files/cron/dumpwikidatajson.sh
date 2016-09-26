#!/bin/bash
#############################################################
# This file is maintained by puppet!
# puppet:///modules/snapshot/cron/dumpwikidatajson.sh
#############################################################
#
# Generate a json dump for Wikidata and remove old ones.
#
# Marius Hoch < hoo@online.de >

. /usr/local/bin/wikidatadumps-shared.sh

filename=wikidata-$today-all
targetFileGzip=$targetDir/$filename.json.gz
targetFileBzip2=$targetDir/$filename.json.bz2
failureFile=/tmp/dumpwikidatajson-failure
mainLogFile=/var/log/wikidatadump/dumpwikidatajson-$filename-main.log

shards=4

# Try to create the dump (up to three times).
retries=0

while true; do
	i=0
	rm -f $failureFile

	while [ $i -lt $shards ]; do
		(
			set -o pipefail
			errorLog=/var/log/wikidatadump/dumpwikidatajson-$filename-$i.log
			php $multiversionscript extensions/Wikidata/extensions/Wikibase/repo/maintenance/dumpJson.php --wiki wikidatawiki --shard $i --sharding-factor $shards --snippet 2>> $errorLog | gzip > $tempDir/wikidataJson.$i.gz
			exitCode=$?
			if [ $exitCode -gt 0 ]; then
				echo -e "\n\nProcess failed with exit code $exitCode" >> $errorLog
				echo 1 > $failureFile
			fi
		) &
		let i++
	done

	wait

	if [ -f $failureFile ]; then
		# Something went wrong, let's clean up and maybe retry. Leave logs in place.
		rm -f $failureFile
		rm -f $tempDir/wikidataJson.*.gz
		let retries++
		echo "Dumping one or more shards failed. Retrying." >> $mainLogFile

		if [ $retries -eq 3 ]; then
			exit 1
		fi

		# Another attempt
		continue
	fi

	break

done

# Open the json list
echo '[' | gzip -f > $tempDir/wikidataJson.gz

i=0
while [ $i -lt $shards ]; do
	tempFile=$tempDir/wikidataJson.$i.gz
	if [ ! -f $tempFile ]; then
		echo "$tempFile does not exist. Aborting." >> $mainLogFile
		exit 1
	fi
	fileSize=`stat --printf="%s" $tempFile`
	if [ $fileSize -lt 1800000000 ]; then
		echo "File size of $tempFile is only $fileSize. Aborting." >> $mainLogFile
		exit 1
	fi
	cat $tempFile >> $tempDir/wikidataJson.gz
	rm $tempFile
	let i++
	if [ $i -lt $shards ]; then
		# Shards don't end with commas so add commas to separate them
		echo ',' | gzip -f >> $tempDir/wikidataJson.gz
	fi
done

# Close the json list
echo -e '\n]' | gzip -f >> $tempDir/wikidataJson.gz

mv $tempDir/wikidataJson.gz $targetFileGzip

# Legacy directory (with legacy naming scheme)
legacyDirectory=$publicDir/other/wikidata
ln -s "../wikibase/wikidatawiki/$today/$filename.json.gz" "$legacyDirectory/$today.json.gz"
find $legacyDirectory -name '*.json.gz' -mtime +`expr $daysToKeep + 1` -delete

# (Re-)create the link to the latest
ln -fs "$today/$filename.json.gz" "$targetDirBase/latest-all.json.gz"

# Create the bzip2 from the gzip one and update the latest-all.json.bz2 link
gzip -dc $targetFileGzip | bzip2 -c > $tempDir/wikidataJson.bz2
mv $tempDir/wikidataJson.bz2 $targetFileBzip2
ln -fs "$today/$filename.json.bz2" "$targetDirBase/latest-all.json.bz2"

pruneOldDirectories
pruneOldLogs
runDcat
