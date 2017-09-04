#!/bin/bash
#############################################################
# This file is maintained by puppet!
# modules/snapshot/cron/dumpcategoriesrdf.sh
#############################################################
#
# Generate an RDF dump of categories for all wikis in
# categories-rdf list and remove old ones.

source /usr/local/etc/set_dump_dirs.sh

checkval() {
    setting=$1
    value=$2
    if [ -z "$value" -o "$value" == "null" ]; then
        echo "failed to retrieve value of $setting from $configfile" >& 2
        exit 1
    fi
}

getsetting() {
    results=$1
    section=$2
    setting=$3
    echo "$results" | /usr/bin/jq -M -r ".$section.$setting"
}

usage() {
	echo "Usage: $0 --list wikis.dblist [--config <pathtofile>] [--dryrun]"
	echo
	echo "  --config  path to configuration file for dump generation"
	echo "            (default value: ${confsdir}/wikidump.conf"
	echo "  --list    file containing list of the wikis to dump"
	echo "  --dryrun  don't run dump, show what would have been done"
	exit 1
}

configFile="${confsdir}/wikidump.conf"
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

args="wiki:dir,privatelist;tools:gzip;output:public"
results=`python "${repodir}/getconfigvals.py" --configfile "$configfile" --args "$args"`

deployDir=`getsetting "$results" "wiki" "dir"` || exit 1
privateList=`getsetting "$results" "wiki" "privatelist"` || exit 1
gzip=`getsetting "$results" "tools" "gzip"` || exit 1
publicDir=`getsetting "$results" "output" "public"` || exit 1

for settingname in "deployDir" "gzip" "privateList" "publicDir"; do
    checkval "$settingname" "${!settingname}"
done

today=$(date +'%Y%m%d')
targetDirBase="${publicDir}/other/categoriesrdf"
targetDir="${targetDirBase}/${today}"
timestampsDir="${targetDirBase}/lastdump"
multiVersionScript="${deployDir}/multiversion/MWScript.php"

# remove old datasets
daysToKeep=70
cutOff=$(( $(date +%s) - $(( $daysToKeep + 1 )) * 24 * 3600))
if [ -d "$targetDirBase" ]; then
	for folder in $(ls -d -r "${targetDirBase}/"*); do
		creationTime=$(date --utc --date="$(basename $folder)" +%s 2>/dev/null)
		if [ -n "$creationTime" ]; then
		    if [ "$cutOff" -gt "$creationTime" ]; then
			if [ "$dryrun" == "true" ]; then
				echo rm "${folder}/"*".${dumpFormat}.gz"
				echo rmdir "${folder}"
			else
				rm -f "${folder}/"*".${dumpFormat}.gz"
				rmdir "${folder}"
			fi
		    fi
		fi
	done
fi

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
