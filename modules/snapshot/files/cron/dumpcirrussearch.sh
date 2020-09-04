#!/bin/bash
#############################################################
# This file is maintained by puppet!
# modules/snapshot/cron/dumpcirrussearch.sh
#############################################################
#
# Generate a json dump of cirrussearch indices for all enabled
# wikis and remove old ones.

source /usr/local/etc/dump_functions.sh

usage() {
	echo "Usage: $0 [--config <pathtofile>] [--dryrun]"
	echo
	echo "  --config  path to configuration file for dump generation"
	echo "            (default value: ${confsdir}/wikidump.conf.other"
	echo "  --dryrun  don't run dump, show what would have been done"
	exit 1
}

configFile="${confsdir}/wikidump.conf.other"
dryrun="false"

while [ $# -gt 0 ]; do
	if [ "$1" = "--config" ]; then
		configFile="$2"
		shift; shift;
	elif [ "$1" = "--dryrun" ]; then
		dryrun="true"
		shift
	else
		echo "$0: Unknown option $1"
		usage
	fi
done

if [ ! -f "$configFile" ]; then
	echo "Could not find config file: $configFile"
	echo "Exiting..."
	exit 1
fi

args="wiki:dblist,privatelist,multiversion;output:temp;tools:gzip,php"
results=$(python3 "${repodir}/getconfigvals.py" --configfile "$configFile" --args "$args")

allList=$(getsetting "$results" "wiki" "dblist") || exit 1
privateList=$(getsetting "$results" "wiki" "privatelist") || exit 1
multiversion=$(getsetting "$results" "wiki" "multiversion") || exit 1
tempDir=$(getsetting "$results" "output" "temp") || exit 1
gzip=$(getsetting "$results" "tools" "gzip") || exit 1
php=$(getsetting "$results" "tools" "php") || exit 1

for settingname in "allList" "privateList" "multiversion" "tempDir" "gzip" "php"; do
    checkval "$settingname" "${!settingname}"
done

function log_err {
	logger --no-act -s -- "$@"
}

today=$(date +'%Y%m%d')
targetDirBase="${cronsdir}/cirrussearch"
targetDir="$targetDirBase/$today"
multiVersionScript="${multiversion}/MWScript.php"
hasErrors=0

# create todays folder
if [ "$dryrun" = "true" ]; then
	echo mkdir -p "$targetDir"
else
	if ! mkdir -p "$targetDir"; then
		echo "Can't make output directory: $targetDir"
		echo "Exiting..."
		exit 1
	fi
fi

# iterate over all known wikis
while read wiki; do
	# exclude all private wikis
	if ! grep -E -q "^$wiki$" "$privateList"; then
		# most wikis only have two indices
		types="content general"
		# commonswiki is special, it also has a file index
		if [ "$wiki" = "commonswiki" ]; then
			types="$types file"
		fi
		# run the dump for each index type
		for type in $types; do
			filename="$wiki-$today-cirrussearch-$type"
			targetFile="$targetDir/$filename.json.gz"
			tempFile="$tempDir/$filename.json.gz"
			if [ -e "$tempFile" ] || [ -e "$targetFile" ]; then
				log_err "$targetFile or $tempFile already exists, skipping..."
				hasErrors=1
			else
				if [ "$dryrun" = "true" ]; then
					echo "$php $multiVersionScript extensions/CirrusSearch/maintenance/DumpIndex.php --wiki=$wiki --indexType=$type 2> /var/log/cirrusdump/cirrusdump-$filename.log | $gzip > $tempFile"
				else
					$php "$multiVersionScript" \
						extensions/CirrusSearch/maintenance/DumpIndex.php \
						--wiki="$wiki" \
						--indexType="$type" \
						2> "/var/log/cirrusdump/cirrusdump-$filename.log" \
						| $gzip > "$tempFile"
					PSTATUS_COPY=( "${PIPESTATUS[@]}" )
					if [ "${PSTATUS_COPY[0]}" = "0" ] && [ "${PSTATUS_COPY[1]}" = "0" ]; then
						mv "$tempFile" "$targetFile"
					else
						log_err "extensions/CirrusSearch/maintenance/DumpIndex.php failed for $targetFile"
						rm "$tempFile"
						hasErrors=1
					fi
				fi
			fi
		done
	fi
done < "$allList"

# dump the metastore index (contains persistent states used by cirrus
# administrative tasks). This index is cluster scoped and not bound to a
# particular wiki (we pass --wiki to mwscript because it's mandatory but this
# option is not used by the script itself)
clusters="eqiad codfw"
for cluster in $clusters; do
	filename="cirrus-metastore-$cluster-$today"
	targetFile="$targetDir/$filename.json.gz"
	if [ "$dryrun" = "true" ]; then
		echo "$php $multiVersionScript extensions/CirrusSearch/maintenance/Metastore.php --wiki=metawiki --dump --cluster=$cluster 2>> /var/log/cirrusdump/cirrusdump-$filename.log | $gzip > ${targetFile}.tmp"
	else
		$php "$multiVersionScript" \
			extensions/CirrusSearch/maintenance/Metastore.php \
			--wiki=metawiki \
			--dump \
			--cluster="$cluster" \
			2>> "/var/log/cirrusdump/cirrusdump-$filename.log" \
			| $gzip > "${targetFile}.tmp"
		mv "${targetFile}.tmp" "$targetFile"
	fi
done



# Maintain a 'current' symlink always pointing at the most recently completed dump
if [ "$dryrun" = "false" ]; then
	cd "$targetDirBase"
        rm -f "current"
	ln -s "$today" "current"
fi

# clean up old log files
find /var/log/cirrusdump/ -name 'cirrusdump-*.log*' -mtime +22 -delete

exit $hasErrors
