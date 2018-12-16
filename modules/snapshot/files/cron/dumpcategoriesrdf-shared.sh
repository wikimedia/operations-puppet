#!/bin/bash
#############################################################
# This file is maintained by puppet!
# modules/snapshot/cron/dumpcategoriesrdf-shared.sh
#############################################################
#
# Shared variable and function declarations for creating Mediawiki category dumps

source /usr/local/etc/dump_functions.sh

configFile="${confsdir}/wikidump.conf.dumps"
dryrun="false"
dbList="categories-rdf"

usage() {
	echo "Usage: $0 --list wikis.dblist [--config <pathtofile>] [--dryrun]"
	echo
	echo "  --config  path to configuration file for dump generation"
	echo "            (default value: ${confsdir}/wikidump.conf.dumps"
	echo "  --list    file containing list of the wikis to dump"
	echo "  --dryrun  don't run dump, show what would have been done"
	exit 1
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

args="wiki:privatelist,multiversion;tools:gzip,php"
results=`python3 "${repodir}/getconfigvals.py" --configfile "$configFile" --args "$args"`

privateList=`getsetting "$results" "wiki" "privatelist"` || exit 1
multiversion=`getsetting "$results" "wiki" "multiversion"` || exit 1
gzip=`getsetting "$results" "tools" "gzip"` || exit 1
php=`getsetting "$results" "tools" "php"` || exit 1

for settingname in "multiversion" "gzip" "privateList"; do
    checkval "$settingname" "${!settingname}"
done

today=$(date +'%Y%m%d')
ts=$(date -u +'%Y%m%d%H%M%S')
multiVersionScript="${multiversion}/MWScript.php"
categoriesDirBase="${cronsdir}/categoriesrdf"
