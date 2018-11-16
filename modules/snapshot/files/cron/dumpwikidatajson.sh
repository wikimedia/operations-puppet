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

if [[ "$1" == '--help' ]]; then
	echo -e "Usage: $0 [--continue]\n"
	echo -e "\t--continue\tAttempt to continue a previous dump run."

	exit
fi

continue=0
if [[ "$1" == '--continue' ]]; then
	shift
	continue=1
else
	# Remove old leftovers, as we start from scratch.
	rm -f $tempDir/wikidataJson.*-batch*.gz
fi

filename=wikidata-$today-all
targetFileGzip=$targetDir/$filename.json.gz
targetFileBzip2=$targetDir/$filename.json.bz2
failureFile=/tmp/dumpwikidatajson-failure
mainLogFile=/var/log/wikidatadump/dumpwikidatajson-$filename-main.log

shards=8

i=0
rm -f $failureFile

getNumberOfBatchesNeeded
numberOfBatchesNeeded=$(($numberOfBatchesNeeded / $shards))

while [ $i -lt $shards ]; do
	(
		set -o pipefail
		errorLog=/var/log/wikidatadump/dumpwikidatajson-$filename-$i.log

		batch=0

		if [ $continue -gt 0 ]; then
			getContinueBatchNumber "$tempDir/wikidataJson.$i-batch*.gz"
		fi

		retries=0
		while [ $batch -lt $numberOfBatchesNeeded ] && [ ! -f $failureFile ]; do
			setPerBatchVars

			echo "(`date --iso-8601=minutes`) Starting batch $batch" >> $errorLog
			# Remove --no-cache once this runs on hhvm (or everything is back on Zend), see T180048.

			# This separates the run-parts by ,\n. For this we assume the last run to not be empty, which should
			# always be the case for Wikidata (given the number of runs needed is rounded down and new pages are
			# added all the time).
			( $php $multiversionscript extensions/Wikibase/repo/maintenance/dumpJson.php \
				--wiki wikidatawiki \
				--shard $i \
				--sharding-factor $shards \
				--batch-size $(($shards * 250)) \
				--snippet 2 \
				--entity-type item \
				--entity-type property \
				--no-cache \
				--dbgroupdefault dump \
				$firstPageIdParam \
				$lastPageIdParam; \
				[ $lastRun -eq 0 ] && echo ',' || true ) \
				2>> $errorLog | gzip -9 > $tempDir/wikidataJson.$i-batch$batch.gz

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

# Open the json list
echo '[' | gzip -f > $tempDir/wikidataJson.gz

i=0
while [ $i -lt $shards ]; do
	getTempFiles "$tempDir/wikidataJson.$i-batch*.gz"
	getFileSize "$tempFiles"
	if [ $fileSize -lt `expr 20000000000 / $shards` ]; then
		echo "File size for shard $i is only $fileSize. Aborting." >> $mainLogFile
		exit 1
	fi
	cat $tempFiles >> $tempDir/wikidataJson.gz
	rm -f $tempFiles
	let i++
	if [ $i -lt $shards ]; then
		# Shards don't end with commas so add commas to separate them
		echo ',' | gzip -f >> $tempDir/wikidataJson.gz
	fi
done

# Close the json list
echo -e '\n]' | gzip -f >> $tempDir/wikidataJson.gz

mv $tempDir/wikidataJson.gz $targetFileGzip
putDumpChecksums $targetFileGzip

# Legacy directory (with legacy naming scheme)
legacyDirectory=${cronsdir}/wikidata
ln -s "../wikibase/wikidatawiki/$today/$filename.json.gz" "$legacyDirectory/$today.json.gz"
find $legacyDirectory -name '*.json.gz' -mtime +`expr $daysToKeep + 1` -delete

# (Re-)create the link to the latest
ln -fs "$today/$filename.json.gz" "$targetDirBase/latest-all.json.gz"

# Create the bzip2 from the gzip one and update the latest-all.json.bz2 link
nthreads=$(( $shards / 2))
if [ $nthreads -lt 1 ]; then
    nthreads=1
fi
gzip -dc $targetFileGzip | "$lbzip2" -n $nthreads -c > $tempDir/wikidataJson.bz2
mv $tempDir/wikidataJson.bz2 $targetFileBzip2
ln -fs "$today/$filename.json.bz2" "$targetDirBase/latest-all.json.bz2"
putDumpChecksums $targetFileBzip2

pruneOldLogs
runDcat
