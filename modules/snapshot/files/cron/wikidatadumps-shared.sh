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

args="wiki:dir;output:temp"
results=`python "${repodir}/getconfigvals.py" --configfile "$configfile" --args "$args"`

apacheDir=`getsetting "$results" "wiki" "dir"` || exit 1
tempDir=`getsetting "$results" "output" "temp"` || exit 1

for settingname in "apacheDir" "tempDir"; do
    checkval "$settingname" "${!settingname}"
done

targetDirBase=${cronsdir}/wikibase/wikidatawiki
targetDir=$targetDirBase/$today

multiversionscript="${apacheDir}/multiversion/MWScript.php"

# Create the dir for the day: This may or may not already exist, we don't care
mkdir -p $targetDir

function pruneOldLogs {
	# Remove old logs (keep 35 days)
	find /var/log/wikidatadump/ -name 'dumpwikidata*-*-*.log' -mtime +36 -delete
}

function runDcat {
	php /usr/local/share/dcat/DCAT.php --config=/usr/local/etc/dcatconfig.json --dumpDir=$targetDirBase --outputDir=$targetDirBase
}
