#!/bin/bash
#############################################################
# This file is maintained by puppet!
# modules/snapshot/cron/wikidatadumps-shared.sh
#############################################################
#
# Shared variable and function declarations for creating Wikidata dumps
#
# Marius Hoch < hoo@online.de >

source /usr/local/etc/dump_functions.sh
configfile="${confsdir}/wikidump.conf.dumps"

today=`date +'%Y%m%d'`
daysToKeep=70
pagesPerBatch=200000

args="wiki:multiversion;output:temp;tools:php,lbzip2"
results=`python "${repodir}/getconfigvals.py" --configfile "$configfile" --args "$args"`

multiversion=`getsetting "$results" "wiki" "multiversion"` || exit 1
tempDir=`getsetting "$results" "output" "temp"` || exit 1
php=`getsetting "$results" "tools" "php"` || exit 1
lbzip2=`getsetting "$results" "tools" "lbzip2"` || exit 1

for settingname in "multiversion" "tempDir"; do
    checkval "$settingname" "${!settingname}"
done

targetDirBase=${cronsdir}/wikibase/wikidatawiki
targetDir=$targetDirBase/$today

multiversionscript="${multiversion}/MWScript.php"

# Create the dir for the day: This may or may not already exist, we don't care
mkdir -p $targetDir

function pruneOldLogs {
	# Remove old logs (keep 35 days)
	find /var/log/wikidatadump/ -name 'dumpwikidata*-*-*.log' -mtime +36 -delete
}

function runDcat {
	$php /usr/local/share/dcat/DCAT.php --config=/usr/local/etc/dcatconfig.json --dumpDir=$targetDirBase --outputDir=$targetDirBase
}

# Add the checksums for $1 to today's checksum files
function putDumpChecksums {
	md5=`md5sum "$1" | awk '{print $1}'`
	echo "$md5  `basename $1`" >> $targetDir/wikidata-$today-md5sums.txt

	sha1=`sha1sum "$1" | awk '{print $1}'`
	echo "$sha1  `basename $1`" >> $targetDir/wikidata-$today-sha1sums.txt
}

# Get the number of batches needed to dump all of Wikidata, stored in $numberOfBatchesNeeded.
function getNumberOfBatchesNeeded {
	maxPageId=`$php $multiversionscript maintenance/sql.php --wiki wikidatawiki --json --query 'SELECT MAX(page_id) AS max_page_id FROM page' | grep max_page_id | grep -oP '\d+'`
	if [[ $maxPageId -lt 1 ]]; then
		echo "Couldn't get MAX(page_id) from db."
		exit 1
	fi

	# This should be roughly enough to dump all pages. The last batch is run without specifying a last page id, so it's ok if this is slightly off.
	numberOfBatchesNeeded=$(($maxPageId / $pagesPerBatch))
}

# Set batch-dependent variables needed for a call to the PHP dump scripts
function setPerBatchVars {
	firstPageIdParam="--first-page-id "$(( $batch * $pagesPerBatch * $shards + 1))
	lastPageIdParam="--last-page-id "$(( ( $batch + 1 ) * $pagesPerBatch * $shards))

	lastRun=0
	if [ $(($batch + 1)) -eq $numberOfBatchesNeeded ]; then
		# Do not limit the last run
		lastPageIdParam=""
		lastRun=1
	fi
}

# Get temporary files selected by the given pattern $1, sorted.
function getTempFiles {
	# Need to use sort -V here as batches need to be concated in order
	tempFiles=`ls -1 $1 2>/dev/null | sort -V | paste -s -d ' '`
}

# Get the total file size of all files in $1
function getFileSize {
	fileSize=`du -b -c $1 | awk '/total$/ { print $1 }'`
}

# Handle the failure of a batch run.
function handleBatchFailure {
	echo -e "\n\n(`date --iso-8601=minutes`) Process for batch $batch of shard $i failed with exit code $exitCode" >> $errorLog

	let retries++

	if [ $retries -gt 5 ]; then
		# Give up with this shard.
		echo -e "\n\n(`date --iso-8601=minutes`) Giving up after $(($retries - 1)) retries." >> $errorLog
		echo 1 > $failureFile
		return 1
	fi

	# Increase the sleep time for every retry
	sleep $((900 * $retries))
}

# Set the last batch number into $batch, based on the given temporary files $1.
function getContinueBatchNumber {
	getTempFiles "$1"
	if [ -n "$tempFiles" ]; then
		batch=`echo $tempFiles | awk '{ print $(NF) }' | sed -r 's/.*batch([0-9]+).gz/\1/'`
	fi
}

# Move file from temp under name $1 to target under name $2 and then link it as latest under name $3
function moveLinkFile {
	tempFile=$1
	targetFile=$2
	latestFile=$3
	mv "$tempDir/$tempFile" "$targetDir/$targetFile"
	ln -fs "$today/$targetFile" "$targetDirBase/$latestFile"
	putDumpChecksums "$targetDir/$targetFile"
}
