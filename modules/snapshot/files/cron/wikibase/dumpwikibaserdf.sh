#!/bin/bash
#############################################################
# This file is maintained by puppet!
# puppet:///modules/snapshot/cron/wikibase/dumpwikibaserdf.sh
#############################################################
#
# Generate a RDF dump for wikibase datasets and remove old ones.
# This script requires a second shell script with function definitions
# in it specific to the given wikibase project and entity types;
# place it in modules/snapshot/cron/wikibase/<projectname>rdf_functions.sh
# using one of the existing files as a guide, and then add the
# project name to PROJECTS below.
# The project name should be the wiki db name without the 'wiki'
# suffix. If someday we move to run wikibase on wiktionaries
# or what have you, we'll redo the project and file name logic!

PROJECTS="wikidata|commons"

source /usr/local/etc/dump_functions.sh

usage() {
    echo "Usage: $0 --project <name> --dump <name> --format <name> [--config <path>]" >& 2
    echo "[--continue] [--dryrun] [--help]" >& 2
    echo >& 2
    echo "Args: " >& 2
    echo "  --config  (-c) path to configuration file for dump generation" >& 2
    echo "                 (default value: ${confsdir}/wikidump.conf.other" >& 2
    echo "  --project (-p) one of 'wikidata' or 'commons'" >& 2
    echo "  --dump    (-d) one of 'all', 'truthy', 'lexemes' (for wikidata)" >& 2
    echo "                 or 'mediainfo' (for commons)" >& 2
    echo "  --format  (-f) output format, one of 'ttl' or 'nt'" >& 2
    echo "  --extra   (-e) convert to this format, one of 'ttl' or 'nt'" >& 2
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
dryrun="false"
continue=0
extraFormat=""

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
	"--format"|"-f")
            dumpFormat="$2"
            shift; shift
	    ;;
	"--extra"|"-e")
            extraFormat="$2"
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
if [ "$projectName" != "wikidata" -a  "$projectName" != "commons" ]; then
    echo -e "Unknown project name."
    usage
    exit 1
fi
if [ -z "$dumpName" ]; then
	echo "Mandatory arg --dump not specified."
	usage
	exit 1
fi
if [ -z "$dumpFormat" ]; then
	echo "Mandatory arg --format not specified."
	usage
	exit 1
fi

. /usr/local/bin/wikibasedumps-shared.sh
. /usr/local/bin/${projectName}rdf_functions.sh

if [ $continue -gt 0 ]; then
	# Remove old leftovers, as we start from scratch.
	rm -f $tempDir/$projectName$dumpFormat-$dumpName.*-batch*.gz
fi

setDumpFlavor

if [[ "$dumpFormat" != "ttl" ]] && [[ "$dumpFormat" != "nt" ]]; then
	echo "Unknown format: $dumpFormat"
	usage
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

setFilename

failureFile="/tmp/dump${projectName}${dumpFormat}-${dumpName}-failure"
logLocation="/var/log/${projectName}dump"
mainLogFile="${logLocation}/dump${projectName}${dumpFormat}-${filename}-main.log"

shards=8

i=0
rm -f $failureFile

setDumpNameToMinSize

getNumberOfBatchesNeeded ${projectName}wiki
numberOfBatchesNeeded=$(($numberOfBatchesNeeded / $shards))

if [[ $numberOfBatchesNeeded -lt 1 ]]; then
# wiki is too small for default settings, change settings to something sane
# this assumes wiki has at least four entities, which sounds plausible
	shards=4
	numberOfBatchesNeeded=1
	pagesPerBatch=$(( $maxPageId / $shards ))
fi

setEntityType

while [ $i -lt $shards ]; do
	(
		set -o pipefail
		errorLog=${logLocation}/dump$projectName$dumpFormat-$filename-$i.log

		batch=0

		if [ $continue -gt 0 ]; then
			getContinueBatchNumber "$tempDir/$projectName$dumpFormat-$dumpName.$i-batch*.gz"
		fi

		retries=0
		while [ $batch -lt $numberOfBatchesNeeded ] && [ ! -f $failureFile ]; do
			setPerBatchVars

			echo "(`date --iso-8601=minutes`) Starting batch $batch" >> $errorLog
			$php $multiversionscript extensions/Wikibase/repo/maintenance/dumpRdf.php \
				--wiki ${projectName}wiki \
				--shard $i \
				--sharding-factor $shards \
				--batch-size $(($shards * 250)) \
				--format $dumpFormat ${dumpFlavor:+--flavor} ${dumpFlavor:+"$dumpFlavor"} \
				$entityTypes \
				--dbgroupdefault dump \
				--part-id $i-$batch \
				$firstPageIdParam \
				$lastPageIdParam 2>> $errorLog | gzip -9 > $tempDir/$projectName$dumpFormat-$dumpName.$i-batch$batch.gz

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
	getTempFiles "$tempDir/$projectName$dumpFormat-$dumpName.$i-batch*.gz"
	if [ -z "$tempFiles" ]; then
		echo "No files for shard $i!" >> $mainLogFile
		exit 1
	fi
	getFileSize "$tempFiles"
	if [ $fileSize -lt ${dumpNameToMinSize[$dumpName]} ]; then
		echo "File size of $tempFile is only $fileSize. Aborting." >> $mainLogFile
		exit 1
	fi
	cat $tempFiles >> $tempDir/$projectName$dumpFormat-$dumpName.gz
	let i++
done

if [ -n "$extraFormat" ]; then
	# Convert primary format to extra format
	i=0
	while [ $i -lt $shards ]; do
		getTempFiles "$tempDir/$projectName$dumpFormat-$dumpName.$i-batch*.gz"
		(
			set -o pipefail
			for tempFile in $tempFiles; do
				extraFile=${tempFile/$projectName$dumpFormat/$projectName$extraFormat}
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
	getTempFiles "$tempDir/$projectName$dumpFormat-$dumpName.$i-batch*.gz"
	rm -f $tempFiles
	if [ -n "$extraFormat" ]; then
		getTempFiles "$tempDir/$projectName$extraFormat-$dumpName.$i-batch*.gz"
		cat $tempFiles >> $tempDir/$projectName$extraFormat-$dumpName.gz
		rm -f $tempFiles
	fi
	let i++
done

nthreads=$(( $shards / 2))
if [ $nthreads -lt 1 ]; then
    nthreads=1
fi

moveLinkFile $projectName$dumpFormat-$dumpName.gz $filename.$dumpFormat.gz latest-$dumpName.$dumpFormat.gz $projectName
gzip -dc "$targetDir/$filename.$dumpFormat.gz" | "$lbzip2" -n $nthreads -c > $tempDir/$projectName$dumpFormat-$dumpName.bz2
moveLinkFile $projectName$dumpFormat-$dumpName.bz2 $filename.$dumpFormat.bz2 latest-$dumpName.$dumpFormat.bz2 $projectName

if [ -n "$extraFormat" ]; then
	moveLinkFile $projectName$extraFormat-$dumpName.gz $filename.$extraFormat.gz latest-$dumpName.$extraFormat.gz $projectName
	gzip -dc "$targetDir/$filename.$extraFormat.gz" | "$lbzip2" -n $nthreads -c > $tempDir/$projectName$extraFormat-$dumpName.bz2
	moveLinkFile $projectName$extraFormat-$dumpName.bz2 $filename.$extraFormat.bz2 latest-$dumpName.$extraFormat.bz2 $projectName
fi

pruneOldLogs
setDcatConfig
runDcat
