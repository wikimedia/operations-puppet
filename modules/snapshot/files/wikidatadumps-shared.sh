#!/bin/bash
#
# Shared variable and function declarations for creating Wikidata dumps
#
# Marius Hoch < hoo@online.de >

configfile="/srv/dumps/confs/wikidump.conf"

apacheDir=`awk -Fdir= '/^dir=/ { print $2 }' "$configfile"`
targetDirBase=`awk -Fpublic= '/^public=/ { print $2 }' "$configfile"`/other/wikibase/wikidatawiki
targetDir=$targetDirBase/`date +'%Y%m%d'`
tempDir=`awk -Ftemp= '/^temp=/ { print $2 }' "$configfile"`
multiversionscript="${apacheDir}/multiversion/MWScript.php"

# Create the dir for the day: This may or may not already exist, we don't care
mkdir -p $targetDir

# Remove dump-folders we no longer need (keep 70 days)
function pruneOldDirectories {
	# Just to be sure: If this were empty the below would work on /
	if [ -z "$targetDirBase" ]; then
		echo "Empty targetDirBase"
		exit 1
	fi

	# Note: We use mtime here, thus if something in the folder has been altered after
	# the date suggested by the name of the folder the folder will stick around longer
	# than 70 days.
	find $targetDirBase -maxdepth 1 -type d -mtime +71 -delete
}

function pruneOldLogs {
	# Remove old logs (keep 35 days)
	find /var/log/wikidatadump/ -name 'dumpwikidata*-*-*.log' -mtime +36 -delete
}
