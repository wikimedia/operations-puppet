#!/bin/bash
#############################################################
# This file is maintained by puppet!
# puppet:///modules/snapshot/cron/dumpwikidatardf.sh
#############################################################
#
# Generate a json dump for Wikidata and remove old ones.
#
# Marius Hoch < hoo@online.de >

. /usr/local/bin/wikidatadumps-shared.sh

declare -A dumpNameToFlavor
dumpNameToFlavor=(["all"]="full-dump" ["truthy"]="truthy-dump")

dumpName=$1

if [ -z "$dumpName" ]; then
	echo "No dump name given."
	exit 1
fi

dumpFlavor=${dumpNameToFlavor[$dumpName]}
if [ -z "$dumpFlavor" ]; then
	echo "Unknown dump name: $dumpName"
	exit 1
fi

dumpFormat=$2

if [[ "$dumpFormat" != "ttl" ]] && [[ "$dumpFormat" != "nt" ]]; then
	echo "Unknown format: $dumpFormat"
	exit 1
fi

filename=wikidata-$today-$dumpName-BETA
targetFileGzip=$targetDir/$filename.$dumpFormat.gz
targetFileBzip2=$targetDir/$filename.$dumpFormat.bz2
failureFile=/tmp/dumpwikidata$dumpFormat-$dumpName-failure
mainLogFile=/var/log/wikidatadump/dumpwikidata$dumpFormat-$filename-main.log

shards=6

declare -A dumpNameToMinSize
# Sanity check: Minimal size we expect each shard of a certain dump to have
dumpNameToMinSize=(["all"]=`expr 23500000000 / $shards` ["truthy"]=`expr 14000000000 / $shards`)

# Try to create the dump (up to three times).
retries=0

while true; do
	i=0
	rm -f $failureFile

	while [ $i -lt $shards ]; do
		(
			set -o pipefail
			errorLog=/var/log/wikidatadump/dumpwikidata$dumpFormat-$filename-$i.log
			# Remove --no-cache once this runs on hhvm (or everything is back on Zend), see T180048.
			php5 $multiversionscript extensions/Wikidata/extensions/Wikibase/repo/maintenance/dumpRdf.php --wiki wikidatawiki --shard $i --sharding-factor $shards --batch-size `expr $shards \* 250` --format $dumpFormat --flavor $dumpFlavor --no-cache 2>> $errorLog | gzip -9 > $tempDir/wikidata$dumpFormat-$dumpName.$i.gz
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
		rm -f $tempDir/wikidata$dumpFormat-$dumpName.*.gz
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
	tempFile=$tempDir/wikidata$dumpFormat-$dumpName.$i.gz
	if [ ! -f $tempFile ]; then
		echo "$tempFile does not exist. Aborting." >> $mainLogFile
		exit 1
	fi
	fileSize=`stat --printf="%s" $tempFile`
	if [ $fileSize -lt ${dumpNameToMinSize[$dumpName]} ]; then
		echo "File size of $tempFile is only $fileSize. Aborting." >> $mainLogFile
		exit 1
	fi
	cat $tempFile >> $tempDir/wikidata$dumpFormat-$dumpName.gz
	rm $tempFile
	let i++
done

mv $tempDir/wikidata$dumpFormat-$dumpName.gz $targetFileGzip
ln -fs "$today/$filename.$dumpFormat.gz" "$targetDirBase/latest-$dumpName.$dumpFormat.gz"

gzip -dc $targetFileGzip | bzip2 -c > $tempDir/wikidata$dumpFormat-$dumpName.bz2
mv $tempDir/wikidata$dumpFormat-$dumpName.bz2 $targetFileBzip2
ln -fs "$today/$filename.$dumpFormat.bz2" "$targetDirBase/latest-$dumpName.$dumpFormat.bz2"


pruneOldDirectories
pruneOldLogs
runDcat
