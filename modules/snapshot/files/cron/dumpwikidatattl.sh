#!/bin/bash
#############################################################
# This file is maintained by puppet!
# puppet:///modules/snapshot/cron/dumpwikidatattl.sh
#############################################################
#
# Generate a json dump for Wikidata and remove old ones.
#
# Marius Hoch < hoo@online.de >

. /usr/local/bin/wikidatadumps-shared.sh

filename=wikidata-$today-all-BETA
targetFileGzip=$targetDir/$filename.ttl.gz
targetFileBzip2=$targetDir/$filename.ttl.bz2
failureFile=/tmp/dumpwikidatattl-failure
mainLogFile=/var/log/wikidatadump/dumpwikidatattl-$filename-main.log

shards=5

# Try to create the dump (up to three times).
retries=0

while true; do
	i=0
	rm -f $failureFile

	while [ $i -lt $shards ]; do
		(
			set -o pipefail
			errorLog=/var/log/wikidatadump/dumpwikidatattl-$filename-$i.log
			php5 $multiversionscript extensions/Wikidata/extensions/Wikibase/repo/maintenance/dumpRdf.php --wiki wikidatawiki --shard $i --sharding-factor $shards --format ttl 2>> $errorLog | gzip > $tempDir/wikidataTTL.$i.gz
			exitCode=$?
			if [ $exitCode -gt 0 ]; then
				echo -e "\n\n(`date --iso-8601=minutes`) Process for shard $i failed with exit code $exitCode" >> $errorLog
				echo 1 > $failureFile

				#  Kill all remaining dumpers and start over.
				pkill -P $$
			fi
		) &
		let i++
	done

	wait

	if [ -f $failureFile ]; then
		# Something went wrong, let's clean up and maybe retry. Leave logs in place.
		rm -f $failureFile
		rm -f $tempDir/wikidataTTL.*.gz
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

i=0
while [ $i -lt $shards ]; do
	tempFile=$tempDir/wikidataTTL.$i.gz
	if [ ! -f $tempFile ]; then
		echo "$tempFile does not exist. Aborting." >> $mainLogFile
		exit 1
	fi
	fileSize=`stat --printf="%s" $tempFile`
	if [ $fileSize -lt 1800000000 ]; then
		echo "File size of $tempFile is only $fileSize. Aborting." >> $mainLogFile
		exit 1
	fi
	cat $tempFile >> $tempDir/wikidataTtl.gz
	rm $tempFile
	let i++
done

mv $tempDir/wikidataTtl.gz $targetFileGzip

gzip -dc $targetFileGzip | bzip2 -c > $tempDir/wikidataTtl.bz2
mv $tempDir/wikidataTtl.bz2 $targetFileBzip2

pruneOldDirectories
pruneOldLogs
runDcat
