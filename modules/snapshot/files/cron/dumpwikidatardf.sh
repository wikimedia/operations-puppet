#!/bin/bash
#############################################################
# This file is maintained by puppet!
# puppet:///modules/snapshot/cron/dumpwikidatardf.sh
#############################################################
#
# Generate a RDF dump for Wikidata and remove old ones.
#
# Marius Hoch < hoo@online.de >

. /usr/local/bin/wikidatadumps-shared.sh

if [[ "$1" == '--help' ]]; then
	echo -e "Usage: $0 [--continue] all|truthy ttl|nt\n"
	echo -e "\t--continue\tAttempt to continue a previous dump run."
	echo -e "\tall|truthy\tType of dump to produce."
	echo -e "\tttl|nt\t\tOutput format."

	exit
fi

continue=0
if [[ "$1" == '--continue' ]]; then
	shift
	continue=1
else
	# Remove old leftovers, as we start from scratch.
	rm -f $tempDir/wikidata$dumpFormat-$dumpName.*-batch*.gz
fi

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

shards=8

i=0
rm -f $failureFile

declare -A dumpNameToMinSize
# Sanity check: Minimal size we expect each shard of a certain dump to have
dumpNameToMinSize=(["all"]=`expr 23500000000 / $shards` ["truthy"]=`expr 14000000000 / $shards`)

getNumberOfBatchesNeeded
numberOfBatchesNeeded=$(($numberOfBatchesNeeded / $shards))

while [ $i -lt $shards ]; do
	(
		set -o pipefail
		errorLog=/var/log/wikidatadump/dumpwikidata$dumpFormat-$filename-$i.log

		batch=0

		if [ $continue -gt 0 ]; then
			getContinueBatchNumber "$tempDir/wikidata$dumpFormat-$dumpName.$i-batch*.gz"
		fi

		retries=0
		while [ $batch -lt $numberOfBatchesNeeded ] && [ ! -f $failureFile ]; do
			setPerBatchVars

			echo "(`date --iso-8601=minutes`) Starting batch $batch" >> $errorLog
			# Remove --no-cache once this runs on hhvm (or everything is back on Zend), see T180048.
			$php $multiversionscript extensions/Wikibase/repo/maintenance/dumpRdf.php \
				--wiki wikidatawiki \
				--shard $i \
				--sharding-factor $shards \
				--batch-size $(($shards * 250)) \
				--format $dumpFormat \
				--flavor $dumpFlavor \
				--entity-type item \
				--entity-type property \
				--no-cache \
				--dbgroupdefault dump \
				--part-id $i-$batch \
				$firstPageIdParam \
				$lastPageIdParam 2>> $errorLog | gzip -9 > $tempDir/wikidata$dumpFormat-$dumpName.$i-batch$batch.gz

			exitCode=$?
			if [ $exitCode -gt 0 ]; then
				handleBatchFailure
				continue
			fi

			retries=0
			let batch++
		done
	) &
	let i++
done

wait

if [ -f $failureFile ]; then
	echo -e "\n\n(`date --iso-8601=minutes`) Giving up after a shard failed." >> $mainLogFile
	rm -f $failureFile

	exit 1
fi

i=0
while [ $i -lt $shards ]; do
	getTempFiles "$tempDir/wikidata$dumpFormat-$dumpName.$i-batch*.gz"
	getFileSize "$tempFiles"
	if [ $fileSize -lt ${dumpNameToMinSize[$dumpName]} ]; then
		echo "File size of $tempFile is only $fileSize. Aborting." >> $mainLogFile
		exit 1
	fi
	cat $tempFiles >> $tempDir/wikidata$dumpFormat-$dumpName.gz
	rm $tempFiles
	let i++
done

mv $tempDir/wikidata$dumpFormat-$dumpName.gz $targetFileGzip
ln -fs "$today/$filename.$dumpFormat.gz" "$targetDirBase/latest-$dumpName.$dumpFormat.gz"
putDumpChecksums $targetFileGzip

gzip -dc $targetFileGzip | bzip2 -c > $tempDir/wikidata$dumpFormat-$dumpName.bz2
mv $tempDir/wikidata$dumpFormat-$dumpName.bz2 $targetFileBzip2
ln -fs "$today/$filename.$dumpFormat.bz2" "$targetDirBase/latest-$dumpName.$dumpFormat.bz2"
putDumpChecksums $targetFileBzip2

pruneOldLogs
runDcat
