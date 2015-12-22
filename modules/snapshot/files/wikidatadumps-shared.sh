#!/bin/bash
#
# Shared variable and function declarations for creating Wikidata dumps
#
# Marius Hoch < hoo@online.de >

configfile="/srv/dumps/confs/wikidump.conf"

today=`date +'%Y%m%d'`
daysToKeep=70

apacheDir=`awk -Fdir= '/^dir=/ { print $2 }' "$configfile"`
publicDir=`awk -Fpublic= '/^public=/ { print $2 }' "$configfile"`
targetDirBase=$publicDir/other/wikibase/wikidatawiki
targetDir=$targetDirBase/$today
tempDir=`awk -Ftemp= '/^temp=/ { print $2 }' "$configfile"`

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
	php5 /usr/local/share/dcat/DCAT.php --config=/usr/local/etc/dcatconfig.json --dumpDir=$targetDirBase --outputDir=$targetDirBase
}
