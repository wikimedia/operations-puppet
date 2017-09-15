#!/bin/bash
#############################################################
# This file is maintained by puppet!
# modules/snapshot/cron/dumpcategoriesrdf-shared.sh
#############################################################
#
# Shared variable and function declarations for creating Mediawiki category dumps

source /usr/local/etc/dump_functions.sh

configFile="${confsdir}/wikidump.conf"
dryrun="false"
dbList="categories-rdf"

usage() {
	echo "Usage: $0 --list wikis.dblist [--config <pathtofile>] [--dryrun]"
	echo
	echo "  --config  path to configuration file for dump generation"
	echo "            (default value: ${confsdir}/wikidump.conf"
	echo "  --list    file containing list of the wikis to dump"
	echo "  --dryrun  don't run dump, show what would have been done"
	exit 1
}

function pruneOldDirs {
	# remove old datasets
	cutOff=$(( $(date +%s) - $(( $daysToKeep + 1 )) * 24 * 3600))
	if [ -d "$targetDirBase" ]; then
		for folder in $(ls -d -r "${targetDirBase}/"*); do
			creationTime=$(date --utc --date="$(basename $folder)" +%s 2>/dev/null)
			if [ -n "$creationTime" ]; then
			    if [ "$cutOff" -gt "$creationTime" ]; then
				if [ "$dryrun" == "true" ]; then
					echo rm "${folder}/*.{$fileSuffix}"
					echo rmdir "${folder}"
				else
					rm -f "${folder}/*.{$fileSuffix}"
					rmdir "${folder}"
				fi
			    fi
			fi
		done
	fi
}

function createFolder {
	# create todays folder
	if [ "$dryrun" == "true" ]; then
		echo mkdir -p "$targetDir"
		echo mkdir -p "$timestampsDir"
	else
		if ! mkdir -p "$targetDir"; then
			echo "Can't make output directory: $targetDir"
			echo "Exiting..."
			exit 1
		fi
		if ! mkdir -p "$timestampsDir"; then
			echo "Can't make output directory: $timestampsDir"
			echo "Exiting..."
			exit 1
		fi
	fi

}

function makeLatestLink {
	# Maintain a 'latest' symlink always pointing at the most recently completed dump
	if [ "$dryrun" == "false" ]; then
		cd "$targetDirBase"
		ln -snf "$today" "latest"
	fi
}

while [ $# -gt 0 ]; do
	if [ $1 == "--config" ]; then
		configFile="$2"
		shift; shift;
	elif [ $1 == "--dryrun" ]; then
		dryrun="true"
		shift
	elif [ $1 == "--list" ]; then
		dbList="$2"
		shift; shift;
	else
		echo "$0: Unknown option $1"
		usage
	fi
done

if [ -z "$dbList" -o ! -f "$dbList" ]; then
	echo "Valid wiki list must be specified"
	echo "Exiting..."
	exit 1
fi

if [ ! -f "$configFile" ]; then
	echo "Could not find config file: $configFile"
	echo "Exiting..."
	exit 1
fi

args="wiki:dir,privatelist;tools:gzip;output:public"
results=`python "${repodir}/getconfigvals.py" --configfile "$configFile" --args "$args"`

deployDir=`getsetting "$results" "wiki" "dir"` || exit 1
privateList=`getsetting "$results" "wiki" "privatelist"` || exit 1
gzip=`getsetting "$results" "tools" "gzip"` || exit 1
publicDir=`getsetting "$results" "output" "public"` || exit 1

for settingname in "deployDir" "gzip" "privateList" "publicDir"; do
    checkval "$settingname" "${!settingname}"
done

multiVersionScript="${deployDir}/multiversion/MWScript.php"
today=$(date -u +'%Y%m%d')
ts=$(date -u +'%Y%m%d%H%M%S')
categoriesDirBase="${publicDir}/other/categoriesrdf"
timestampsDir="${targetDirBase}/lastdump"
