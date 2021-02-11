#!/bin/bash
#############################################################
# This file is maintained by puppet!
# puppet:///modules/snapshot/cron/dumpwikidatajson.sh
#############################################################
#
# Generate a json dump for Wikidata and remove old ones.
#
# Marius Hoch < hoo@online.de >

# when/if commons or other projects are included in json entity
# dumps, this script can become dumpwikibasejson.sh with shared
# functions analogous to the rdf dumps. For now however, hardcode
# the projectName here and leave the rest alone.

PROJECTS=("wikidata")

source /usr/local/etc/dump_functions.sh

usage() {
    echo "Usage: $0 --project <name> --dump <name> --format <name> [--config <path>]" >& 2
    echo "[--continue] [--dryrun] [--help]" >& 2
    echo >& 2
    echo "Args: " >& 2
    echo "  --config   (-c) path to configuration file for dump generation" >& 2
    echo "                  (default value: ${confsdir}/wikidump.conf.other" >& 2
    echo "  --project  (-p) 'wikidata' (soon to be expanded)" >& 2
    echo "                  (default value: wikidata)" >& 2
    echo "  --dump     (-d) 'all' or 'lexemes' (for wikidata)" >& 2
    echo "                  (default value: all)" >& 2
    echo "  --entities (-e) one of 'item|property' or 'lexemes' (for wikidata)" >& 2
    echo >& 2
    echo "Flags: " >& 2
    echo "  --continue (-C) resume the specified dump from where it left off" >& 2
    echo "                  (default value: false)" >& 2
    echo "  --dryrun   (-D) don't run dump, show what would have been done" >& 2
    echo "                  (default value: false)" >& 2
    echo "  --help     (-h) show this help message" >& 2
    exit 1
}

configfile="${confsdir}/wikidump.conf.other"
projectName="wikidata"
dumpName="all"
entities="item|property"
dryrun="false"
continue=0

#. /usr/local/bin/wikibasedumps-shared.sh

while [ $# -gt 0 ]; do
    case "$1" in
	"--config"|"-c")
            configfile="$2"
            shift; shift
	    ;;
	"--project"|"-p")
            projectName="$2"
            shift; shift
	    ;;
	"--dump"|"-d")
            dumpName="$2"
            shift; shift
	    ;;
	"--entities"|"-e")
            entities="$2"
            shift; shift
	    ;;
	"--dryrun"|"-D")
            dryrun="true"
            shift
	    ;;
	"--continue"|"-C")
            continue=1
            shift
	    ;;
	"--help"|"-h")
	    usage && exit 1
	    ;;
	*)
            echo "$0: Unknown option $1" >& 2
            usage && exit 1
	    ;;
    esac
done

if [ -z "$projectName" ]; then
    echo -e "Mandatory arg --project not specified."
    usage
    exit 1
fi

projectOK=""
for value in "${PROJECTS[@]}"; do
  if [ "$value" == "$projectName" ]; then
      projectOK="true"
      break;
  fi
done
if [ -z "$projectOK" ]; then
    echo -e "Unknown project name."
    usage
    exit 1
fi

IFS='|' read -r -a entityArray <<< "$entities"
entityTypes=()
for value in "${entityArray[@]}"; do
  entityTypes+=("--entity-type")
  entityTypes+=("$value")
done

minSize=58000000000 # across all shards (to be divided by $shards)
if [[ "$dumpName" == "lexemes" ]]; then
	minSize=100000000
fi

if [ $continue -eq 0 ]; then
	# Remove old leftovers, as we start from scratch.
	rm -f $tempDir/wikidataJson$dumpName.*-batch*.gz
fi

filename=wikidata-$today-$dumpName
targetFileGzip=$targetDir/$filename.json.gz
targetFileBzip2=$targetDir/$filename.json.bz2
failureFile=/tmp/dumpwikidatajson-$dumpName-failure
mainLogFile=/var/log/wikidatadump/dumpwikidatajson-$filename-main.log

shards=8

i=0
rm -f $failureFile

getNumberOfBatchesNeeded
numberOfBatchesNeeded=$(($numberOfBatchesNeeded / $shards))
function returnWithCode { return $1; }

while [ $i -lt $shards ]; do
	(
		set -o pipefail
		errorLog=/var/log/wikidatadump/dumpwikidatajson-$filename-$i.log

		batch=0

		if [ $continue -gt 0 ]; then
			getContinueBatchNumber "$tempDir/wikidataJson$dumpName.$i-batch*.gz"
		fi

		retries=0
		while [ $batch -lt $numberOfBatchesNeeded ] && [ ! -f $failureFile ]; do
			setPerBatchVars

			echo "(`date --iso-8601=minutes`) Starting batch $batch" >> $errorLog
			# This separates the run-parts by ,\n. For this we assume the last run to not be empty, which should
			# always be the case for Wikidata (given the number of runs needed is rounded down and new pages are
			# added all the time).
			( $php $multiversionscript extensions/Wikibase/repo/maintenance/dumpJson.php \
				--wiki wikidatawiki \
				--shard $i \
				--sharding-factor $shards \
				--batch-size $(($shards * 250)) \
				--snippet 2 \
				"${entityTypes[@]}" \
				--dbgroupdefault dump \
				$firstPageIdParam \
				$lastPageIdParam; \
				dumpExitCode=$?; \
				[ $lastRun -eq 0 ] && echo ','; \
				returnWithCode $dumpExitCode ) \
				2>> $errorLog | gzip -9 > $tempDir/wikidataJson$dumpName.$i-batch$batch.gz

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
echo '[' | gzip -f > $tempDir/wikidataJson$dumpName.gz

minSizePerShard=$((minSize / shards))
i=0
while [ $i -lt $shards ]; do
	getTempFiles "$tempDir/wikidataJson$dumpName.$i-batch*.gz"
	getFileSize "$tempFiles"
	if (( fileSize < minSizePerShard )); then
		echo "File size for shard $i is only $fileSize, expecting at least $minSizePerShard. Aborting." >> $mainLogFile
		exit 1
	fi
	cat $tempFiles >> $tempDir/wikidataJson$dumpName.gz
	rm -f $tempFiles
	let i++
	if [ $i -lt $shards ]; then
		# Shards don't end with commas so add commas to separate them
		echo ',' | gzip -f >> $tempDir/wikidataJson$dumpName.gz
	fi
done

# Close the json list
echo -e '\n]' | gzip -f >> $tempDir/wikidataJson$dumpName.gz

mv $tempDir/wikidataJson$dumpName.gz $targetFileGzip
putDumpChecksums $targetFileGzip

# Legacy directory (with legacy naming scheme)
legacyDirectory=${cronsdir}/wikidata
ln -s "../wikibase/wikidatawiki/$today/$filename.json.gz" "$legacyDirectory/$today.json.gz"
find $legacyDirectory -name '*.json.gz' -mtime +`expr $daysToKeep + 1` -delete

# (Re-)create the link to the latest
ln -fs "$today/$filename.json.gz" "$targetDirBase/latest-$dumpName.json.gz"

# Create the bzip2 from the gzip one and update the latest-....json.bz2 link
nthreads=$(( $shards / 2))
if [ $nthreads -lt 1 ]; then
    nthreads=1
fi
gzip -dc $targetFileGzip | "$lbzip2" -n $nthreads -c > $tempDir/wikidataJson$dumpName.bz2
mv $tempDir/wikidataJson$dumpName.bz2 $targetFileBzip2
ln -fs "$today/$filename.json.bz2" "$targetDirBase/latest-$dumpName.json.bz2"
putDumpChecksums $targetFileBzip2

pruneOldLogs
runDcat
