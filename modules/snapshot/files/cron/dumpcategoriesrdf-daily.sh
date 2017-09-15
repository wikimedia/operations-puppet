#!/bin/bash
#############################################################
# This file is maintained by puppet!
# modules/snapshot/cron/dumpcategoriesrdf-daily.sh
#############################################################
#
# Generate a daily list of changes for all wikis in
# categories-rdf list and remove old ones.

source /usr/local/etc/dump_functions.sh

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
results=`python "${repodir}/getconfigvals.py" --configfile "$configFile" --args "$args"`

deployDir=`getsetting "$results" "wiki" "dir"` || exit 1
privateList=`getsetting "$results" "wiki" "privatelist"` || exit 1
gzip=`getsetting "$results" "tools" "gzip"` || exit 1
publicDir=`getsetting "$results" "output" "public"` || exit 1

for settingname in "deployDir" "gzip" "privateList" "publicDir"; do
    checkval "$settingname" "${!settingname}"
done

today=$(date -u +'%Y%m%d')
ts=$(date -u +'%Y%m%d%H%M%S')
fullDumpDirBase="${publicDir}/other/categoriesrdf"
timestampsDir="${fullDumpDirBase}/lastdump"
targetDir="${fullDumpDirBase}/daily/${today}"
multiVersionScript="${deployDir}/multiversion/MWScript.php"

# remove old datasets
daysToKeep=15
cutOff=$(( $(date +%s) - $(( $daysToKeep + 1 )) * 24 * 3600))
if [ -d "$targetDirBase" ]; then
	for folder in $(ls -d -r "${targetDirBase}/"*); do
		creationTime=$(date --utc --date="$(basename $folder)" +%s 2>/dev/null)
		if [ -n "$creationTime" ]; then
		    if [ "$cutOff" -gt "$creationTime" ]; then
			if [ "$dryrun" == "true" ]; then
				echo rm "${folder}/"*".sparql.gz"
				echo rmdir "${folder}"
			else
				rm -f "${folder}/"*".sparql.gz"
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
		filename="${wiki}-${today}-daily"
		targetFile="${targetDir}/${filename}.sparql.gz"
		tsFile="${timestampsDir}/${wiki}-daily.last"
		fullTsFile="${timestampsDir}/${wiki}-categories.last"
		# get latest timestamps
		if [ -f "$fullTsFile" ]; then
			fullTs=`cat $fullTsFile`
		fi
		if [ -z "$fullTs" ]; then
			echo "Can not find full dump timestamp at $fullTsFile!"
			continue
		fi
		if [ -f "$tsFile" ]; then
			lastTs=`cat $tsFile`
		fi
		if [ -z "$lastTs"]; then
			lastTs=$fullTs
		fi
		# if dump is more recent than last daily, we have to generate diff between dump and now
		if [ "$fullTs" -gt "$lastTs" ]; then
			if [ "$dryrun" == "true" ]; then
				# get only day TS
				dumpTs=${fullTs:0:8}
				echo "php $multiVersionScript maintenance/categoryChangesAsRdf.php --wiki=$wiki -s $fullTs -e $ts 2> /var/log/categoriesrdf/${filename}-daily.log | $gzip > fromDump${dumpTs}-${targetFile}"
			else
				php "$multiVersionScript" maintenance/categoryChangesAsRdf.php --wiki="$wiki" -s $fullTs -e $ts 2> "/var/log/categoriesrdf/${filename}-daily.log" | "$gzip" > "fromDump${dumpTs}-${targetFile}"
			fi
		fi
		# create daily diff
		if [ "$dryrun" == "true" ]; then
			echo "php $multiVersionScript maintenance/categoryChangesAsRdf.php --wiki=$wiki -s $lastTs -e $ts 2>> /var/log/categoriesrdf/${filename}-daily.log | $gzip > $targetFile"
		else
			php "$multiVersionScript" maintenance/categoryChangesAsRdf.php --wiki="$wiki" -s $lastTs -e $ts 2>> "/var/log/categoriesrdf/${filename}-daily.log" | "$gzip" > "$targetFile"
			echo "$ts" > "$tsFile"
		fi

	fi
done


# Maintain a 'latest' symlink always pointing at the most recently completed dump
if [ "$dryrun" == "false" ]; then
	cd "$targetDirBase"
	ln -snf "$today" "latest"
fi
