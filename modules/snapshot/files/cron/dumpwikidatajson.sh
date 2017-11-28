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

shards=6

# Try to create the dump (up to three times).
retries=0

while true; do
	i=0
	rm -f $failureFile

	while [ $i -lt $shards ]; do
		(
			set -o pipefail
			errorLog=/var/log/wikidatadump/dumpwikidatajson-$filename-$i.log
			# Remove --no-cache once this runs on hhvm (or everything is back on Zend), see T180048.
			php5 $multiversionscript extensions/Wikidata/extensions/Wikibase/repo/maintenance/dumpJson.php --wiki wikidatawiki --shard $i --sharding-factor $shards --batch-size `expr $shards \* 250` --snippet 2 --no-cache 2>> $errorLog | gzip -9 > $tempDir/wikidataJson.$i.gz
			exitCode=$?
			if [ $exitCode -gt 0 ]; then
				echo -e "\n\n(`date --iso-8601=minutes`) Process for shard $i failed with exit code $exitCode" >> $errorLog
				echo 1 > $failureFile

				#  Kill all sub*-processes of the (parent) bash process and start over
				killAllSubProcesses
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
		echo "(`date --iso-8601=minutes`) Dumping one or more shards failed. Retrying." >> $mainLogFile

		if [ $retries -eq 3 ]; then
			exit 1
		fi

		# Wait 10 minutes (in case of database problems or other instabilities), then try again
		sleep 600
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
	if [ $fileSize -lt `expr 20000000000 / $shards` ]; then
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
legacyDirectory=${otherdir}/wikidata
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
