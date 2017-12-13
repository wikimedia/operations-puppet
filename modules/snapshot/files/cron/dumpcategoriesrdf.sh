#!/bin/bash
#############################################################
# This file is maintained by puppet!
# modules/snapshot/cron/dumpcategoriesrdf.sh
#############################################################
#
# Generate an RDF dump of categories for all wikis in
# categories-rdf list and remove old ones.

source /usr/local/etc/dump_functions.sh

usage() {
	echo "Usage: $0 --list wikis.dblist [--config <pathtofile>] [--dryrun]"
	echo
	echo "  --config  path to configuration file for dump generation"
	echo "            (default value: ${confsdir}/wikidump.conf.dumps"
	echo "  --list    file containing list of the wikis to dump"
	echo "  --dryrun  don't run dump, show what would have been done"
	exit 1
}

configFile="${confsdir}/wikidump.conf.dumps"
dryrun="false"
dumpFormat="ttl"
dbList="categories-rdf"

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

args="wiki:privatelist;tools:gzip"
results=`python "${repodir}/getconfigvals.py" --configfile "$configFile" --args "$args"`

privateList=`getsetting "$results" "wiki" "privatelist"` || exit 1
gzip=`getsetting "$results" "tools" "gzip"` || exit 1

for settingname in "gzip" "privateList"; do
    checkval "$settingname" "${!settingname}"
done

today=$(date +'%Y%m%d')
targetDirBase="${cronsdir}/categoriesrdf"
targetDir="${targetDirBase}/${today}"
timestampsDir="${targetDirBase}/lastdump"
multiVersionScript="${apachedir}/multiversion/MWScript.php"

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

# iterate over configured wikis
cat "$dbList" | while read wiki; do
	# exclude all private wikis
	if ! egrep -q "^${wiki}$" "$privateList"; then
		filename="${wiki}-${today}-categories"
		targetFile="${targetDir}/${filename}.${dumpFormat}.gz"
		tsFile="${timestampsDir}/${wiki}-categories.last"
		if [ "$dryrun" == "true" ]; then
			echo "php $multiVersionScript maintenance/dumpCategoriesAsRdf.php --wiki=$wiki --format=$dumpFormat 2> /var/log/categoriesrdf/${filename}.log | $gzip > $targetFile"
		else
			php "$multiVersionScript" maintenance/dumpCategoriesAsRdf.php --wiki="$wiki" --format="$dumpFormat" 2> "/var/log/categoriesrdf/${filename}.log" | "$gzip" > "$targetFile"
			echo "$today" > "$tsFile"
		fi
	fi
done


# Maintain a 'latest' symlink always pointing at the most recently completed dump
if [ "$dryrun" == "false" ]; then
	cd "$targetDirBase"
	ln -snf "$today" "latest"
fi
