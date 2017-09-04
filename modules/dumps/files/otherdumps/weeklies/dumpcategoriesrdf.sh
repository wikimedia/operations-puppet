#!/bin/bash
#############################################################
# This file is maintained by puppet!
# modules/dumps/otherdumps/weeklies/dumpcategoriesrdf.sh
#############################################################
#
# Generate an RDF dump of categories for all wikis in
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

configfile="${confsdir}/wikidump.conf"
dryrun="false"
dumpFormat="ttl"
dbList="categories-rdf"

while [ $# -gt 0 ]; do
	if [ $1 == "--config" ]; then
		configfile="$2"
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

if [ ! -f "$configfile" ]; then
	echo "Could not find config file: $configfile"
	echo "Exiting..."
	exit 1
fi

args="wiki:dir,privatelist;tools:gzip,php;output:public"
results=$( /usr/bin/python "${repodir}/getconfigvals.py" --configfile "$configfile" --args "$args" )

deployDir=$( getsetting "$results" "wiki" "dir" ) || exit 1
privateList=$( getsetting "$results" "wiki" "privatelist" ) || exit 1
gzip=$( getsetting "$results" "tools" "gzip" ) || exit 1
php=$( getsetting "$results" "tools" "php" ) || exit 1

for settingname in "deployDir" "gzip" "privateList" "php"; do
    checkval "$settingname" "${!settingname}"
done

today=$( /bin/date +'%Y%m%d' )
targetDirBase="${otherdumpsdir}/categoriesrdf"
targetDir="${targetDirBase}/${today}"
timestampsDir="${targetDirBase}/lastdump"
multiVersionScript="${deployDir}/multiversion/MWScript.php"

# remove old datasets
daysToKeep=70
cutOff=$(( $( /bin/date +%s ) - $(( $daysToKeep + 1 )) * 24 * 3600))
if [ -d "$targetDirBase" ]; then
	for folder in $(/bin/ls -d -r "${targetDirBase}/"*); do
                creationTime=$( /bin/date --utc --date="$(basename $folder )" +%s 2>/dev/null)
                if [ -n "$creationTime" ]; then
                    if [ "$cutOff" -gt "$creationTime" ]; then
			if [ "$dryrun" == "true" ]; then
				echo /bin/rm "${folder}/"*".${dumpFormat}.gz"
				echo /bin/rmdir "${folder}"
			else
				/bin/rm -f "${folder}/"*".${dumpFormat}.gz"
				/bin/rmdir "${folder}"
			fi
		    fi
		fi
	done
fi

# create todays folder
if [ "$dryrun" == "true" ]; then
	echo /bin/mkdir -p "$targetDir"
	echo /bin/mkdir -p "$timestampsDir"
else
	if ! /bin/mkdir -p "$targetDir"; then
		echo "Can't make output directory: $targetDir"
		echo "Exiting..."
		exit 1
	fi
	if ! /bin/mkdir -p "$timestampsDir"; then
		echo "Can't make output directory: $timestampsDir"
		echo "Exiting..."
		exit 1
	fi
fi

# iterate over configured wikis
/bin/cat "$dbList" | while read wiki; do
	# exclude all private wikis
	if ! /bin/egrep -q "^${wiki}$" "$privateList"; then
		filename="${wiki}-${today}-categories"
		targetFile="${targetDir}/${filename}.${dumpFormat}.gz"
		tsFile="${timestampsDir}/${wiki}-categories.last"
		if [ "$dryrun" == "true" ]; then
			echo "${php} ${multiVersionScript} maintenance/dumpCategoriesAsRdf.php --wiki=${wiki} --format=${dumpFormat} 2> /var/log/categoriesrdf/${filename}.log | ${gzip} > ${targetFile}"
		else
                        "$php" "$multiVersionScript" maintenance/dumpCategoriesAsRdf.php \
                            "--wiki=${wiki}" \
                            "--format=${dumpFormat}" 2> "/var/log/categoriesrdf/${filename}.log" \
                           | "$gzip" > "$targetFile"
			echo "$today" > "$tsFile"
		fi
	fi
done


# Maintain a 'latest' symlink always pointing at the most recently completed dump
if [ "$dryrun" == "false" ]; then
	cd "$targetDirBase"
	/bin/ln -snf "$today" "latest"
fi
