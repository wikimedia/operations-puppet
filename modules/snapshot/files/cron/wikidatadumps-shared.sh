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
pagesPerBatch=400000

args="output:temp;tools:php"
results=`python "${repodir}/getconfigvals.py" --configfile "$configfile" --args "$args"`

tempDir=`getsetting "$results" "output" "temp"` || exit 1
php=`getsetting "$results" "tools" "php"` || exit 1

for settingname in "tempDir"; do
    checkval "$settingname" "${!settingname}"
done

targetDirBase=${cronsdir}/wikibase/wikidatawiki
targetDir=$targetDirBase/$today

multiversionscript="${apachedir}/multiversion/MWScript.php"

# Create the dir for the day: This may or may not already exist, we don't care
mkdir -p $targetDir

function pruneOldLogs {
	# Remove old logs (keep 35 days)
	find /var/log/wikidatadump/ -name 'dumpwikidata*-*-*.log' -mtime +36 -delete
}

function runDcat {
	$php /usr/local/share/dcat/DCAT.php --config=/usr/local/etc/dcatconfig.json --dumpDir=$targetDirBase --outputDir=$targetDirBase
}

function putDumpChecksums {
	md5=`md5sum "$1" | awk '{print $1}'`
	echo "$md5  `basename $1`" >> $targetDir/wikidata-$today-md5sums.txt

	sha1=`sha1sum "$1" | awk '{print $1}'`
	echo "$sha1  `basename $1`" >> $targetDir/wikidata-$today-sha1sums.txt
}

function getNumberOfBatchesNeeded {
	maxPageId=`$php $multiversionscript maintenance/sql.php --wiki wikidatawiki --json --query 'SELECT MAX(page_id) AS max_page_id FROM page' | grep max_page_id | grep -oP '\d+'`

	# This should be roughly enough to dump all pages. The last batch is run without specifying a last page id, so it's ok if this is slightly off.
	numberOfBatchesNeeded=`echo "$maxPageId / $pagesPerBatch" | bc`
}
