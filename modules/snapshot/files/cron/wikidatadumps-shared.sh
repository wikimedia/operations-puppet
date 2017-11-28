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
configfile="${confsdir}/wikidump.conf"

today=`date +'%Y%m%d'`
daysToKeep=70

args="wiki:dir;output:temp"
results=`python "${repodir}/getconfigvals.py" --configfile "$configfile" --args "$args"`

apacheDir=`getsetting "$results" "wiki" "dir"` || exit 1
tempDir=`getsetting "$results" "output" "temp"` || exit 1

for settingname in "apacheDir" "tempDir"; do
    checkval "$settingname" "${!settingname}"
done

targetDirBase=${otherdir}/wikibase/wikidatawiki
targetDir=$targetDirBase/$today

multiversionscript="${apacheDir}/multiversion/MWScript.php"

# Create the dir for the day: This may or may not already exist, we don't care
mkdir -p $targetDir

# Remove dump-folders we no longer need (keep $daysToKeep days)
function pruneOldDirectories {
	# Just to be sure: If this were empty the below would work on /
	if [ -z "$targetDirBase" ]; then
		echo "Empty \$targetDirBase"
		exit 1
	fi

	cutOff=$(( `date +%s` - `expr $daysToKeep + 1` * 24 * 3600)) # Timestamp from $daysToKeep + 1 days ago
	foldersToDelete=`ls -d -r $targetDirBase/*` # $targetDirBase is known to be non-empty
	for folder in $foldersToDelete; do
		# Try to get the unix time from the folder name, if this fails we'll just
		# keep the folder (as it's not a valid date, thus hasn't been created by this script).
		creationTime=$(date --utc --date="$(basename $folder)" +%s 2>/dev/null)
		if [ -n "$creationTime" ] && [ "$cutOff" -gt "$creationTime" ]; then
			rm -rf $folder
		fi
	done
}

function pruneOldLogs {
	# Remove old logs (keep 35 days)
	find /var/log/wikidatadump/ -name 'dumpwikidata*-*-*.log' -mtime +36 -delete
}

function runDcat {
	php /usr/local/share/dcat/DCAT.php --config=/usr/local/etc/dcatconfig.json --dumpDir=$targetDirBase --outputDir=$targetDirBase
}

function killAllSubProcesses {
	# Get all processes with this SID
	PIDS=`pgrep --session $(ps o sid --no-headers $$)`

	# Make sure we're not killing ourselves
	PIDS=`echo $PIDS | sed "s/\b$$\b//g"`

	# Use nohup here to make sure the kill is not getting stopped itself
	nohup kill $PIDS > /dev/null
}
