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
	echo -e "Usage: $0 [--continue] all|truthy|lexemes ttl|nt [nt|ttl]\n"
	echo -e "\t--continue\tAttempt to continue a previous dump run."
	echo -e "\tall|truthy|lexemes\tType of dump to produce."
	echo -e "\tttl|nt\t\tOutput format."
	echo -e "\t[nt|ttl]\t\tOutput format for extra dump, converted from above (optional)."

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
dumpNameToFlavor=(["all"]="full-dump" ["truthy"]="truthy-dump" ["lexemes"]="full-dump")

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
extraFormat=$3

if [[ "$dumpFormat" != "ttl" ]] && [[ "$dumpFormat" != "nt" ]]; then
	echo "Unknown format: $dumpFormat"
	exit 1
fi

if [ -n "$extraFormat" ]; then
	declare -A serdiDumpFormats
	serdiDumpFormats=(["ttl"]="turtle" ["nt"]="ntriples")
	extraIn=${serdiDumpFormats[$dumpFormat]}
	extraOut=${serdiDumpFormats[$extraFormat]}
	if [ -z "$extraIn" -o -z "$extraOut" -o "$extraIn" = "$extraOut" ]; then
		extraFormat=""
	fi
fi

filename=wikidata-$today-$dumpName
failureFile=/tmp/dumpwikidata$dumpFormat-$dumpName-failure
mainLogFile=/var/log/wikidatadump/dumpwikidata$dumpFormat-$filename-main.log

shards=8

i=0
rm -f $failureFile

declare -A dumpNameToMinSize
# Sanity check: Minimal size we expect each shard of a certain dump to have
dumpNameToMinSize=(["all"]=`expr 56000000000 / $shards` ["truthy"]=`expr 30000000000 / $shards` ["lexemes"]=`expr 9000000 / $shards`)

getNumberOfBatchesNeeded
numberOfBatchesNeeded=$(($numberOfBatchesNeeded / $shards))

if [[ $numberOfBatchesNeeded -lt 1 ]]; then
# wiki is too small for default settings, change settings to something sane
# this assumes wiki has at least four entities, which sounds plausible
	shards=4
	numberOfBatchesNeeded=1
	pagesPerBatch=$(( $maxPageId / $shards ))
fi

if [[ "$dumpName" == "lexemes" ]]; then
	entityTypes="--entity-type lexeme"
else
	entityTypes="--entity-type item --entity-type property"
fi

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
				$entityTypes \
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
	if [ -z "$tempFiles" ]; then
		echo "No files for shard $i!" >> $mainLogFile
		exit 1
	fi
	getFileSize "$tempFiles"
	if [ $fileSize -lt ${dumpNameToMinSize[$dumpName]} ]; then
		echo "File size of $tempFile is only $fileSize. Aborting." >> $mainLogFile
		exit 1
	fi
	cat $tempFiles >> $tempDir/wikidata$dumpFormat-$dumpName.gz
	let i++
done

if [ -n "$extraFormat" ]; then
	# Convert primary format to extra format
	i=0
	while [ $i -lt $shards ]; do
		getTempFiles "$tempDir/wikidata$dumpFormat-$dumpName.$i-batch*.gz"
		(
			set -o pipefail
			for tempFile in $tempFiles; do
				extraFile=${tempFile/wikidata$dumpFormat/wikidata$extraFormat}
				gzip -dc $tempFile | serdi -i $extraIn -o $extraOut -b -q - | gzip -9 > $extraFile
				exitCode=$?
				if [ $exitCode -gt 0 ]; then
					echo -e "\n\n(`date --iso-8601=minutes`) Converting $tempFile failed with exit code $exitCode" >> $errorLog
				fi
			done
		) &
		let i++
	done
	wait
fi

i=0
while [ $i -lt $shards ]; do
	getTempFiles "$tempDir/wikidata$dumpFormat-$dumpName.$i-batch*.gz"
	rm -f $tempFiles
	if [ -n "$extraFormat" ]; then
		getTempFiles "$tempDir/wikidata$extraFormat-$dumpName.$i-batch*.gz"
		cat $tempFiles >> $tempDir/wikidata$extraFormat-$dumpName.gz
		rm -f $tempFiles
	fi
	let i++
done

nthreads=$(( $shards / 2))
if [ $nthreads -lt 1 ]; then
    nthreads=1
fi

moveLinkFile wikidata$dumpFormat-$dumpName.gz $filename.$dumpFormat.gz latest-$dumpName.$dumpFormat.gz
gzip -dc "$targetDir/$filename.$dumpFormat.gz" | "$lbzip2" -n $nthreads -c > $tempDir/wikidata$dumpFormat-$dumpName.bz2
moveLinkFile wikidata$dumpFormat-$dumpName.bz2 $filename.$dumpFormat.bz2 latest-$dumpName.$dumpFormat.bz2

if [ -n "$extraFormat" ]; then
	moveLinkFile wikidata$extraFormat-$dumpName.gz $filename.$extraFormat.gz latest-$dumpName.$extraFormat.gz
	gzip -dc "$targetDir/$filename.$extraFormat.gz" | "$lbzip2" -n $nthreads -c > $tempDir/wikidata$extraFormat-$dumpName.bz2
	moveLinkFile wikidata$extraFormat-$dumpName.bz2 $filename.$extraFormat.bz2 latest-$dumpName.$extraFormat.bz2
fi

pruneOldLogs
runDcat
