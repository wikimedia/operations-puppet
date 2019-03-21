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
	if [ $1 == "--config" ]; then
		configFile="$2"
		shift; shift;
	elif [ $1 == "--dryrun" ]; then
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

args="wiki:dblist,privatelist,multiversion;tools:gzip,php"
results=`python3 "${repodir}/getconfigvals.py" --configfile "$configFile" --args "$args"`

allList=`getsetting "$results" "wiki" "dblist"` || exit 1
privateList=`getsetting "$results" "wiki" "privatelist"` || exit 1
multiversion=`getsetting "$results" "wiki" "multiversion"` || exit 1
gzip=`getsetting "$results" "tools" "gzip"` || exit 1
php=`getsetting "$results" "tools" "php"` || exit 1

for settingname in "allList" "privateList" "multiversion" "gzip"; do
    checkval "$settingname" "${!settingname}"
done

today=$(date +'%Y%m%d')
targetDirBase="${cronsdir}/cirrussearch"
targetDir="$targetDirBase/$today"
multiVersionScript="${multiversion}/MWScript.php"

# create todays folder
if [ "$dryrun" == "true" ]; then
	echo mkdir -p "$targetDir"
else
	if ! mkdir -p "$targetDir"; then
		echo "Can't make output directory: $targetDir"
		echo "Exiting..."
		exit 1
	fi
fi

# iterate over all known wikis
cat $allList | while read wiki; do
	# exclude all private wikis
	if ! egrep -q "^$wiki$" $privateList; then
		# most wikis only have two indices
		types="content general"
		# commonswiki is special, it also has a file index
		if [ "$wiki" == "commonswiki" ]; then
			types="$types file"
		fi
		# run the dump for each index type
		for type in $types; do
			filename="$wiki-$today-cirrussearch-$type"
			targetFile="$targetDir/$filename.json.gz"
			if [ "$dryrun" == "true" ]; then
				echo "$php $multiVersionScript extensions/CirrusSearch/maintenance/dumpIndex.php --wiki=$wiki --indexType=$type 2> /var/log/cirrusdump/cirrusdump-$filename.log | $gzip > $targetFile"
			else
				$php $multiVersionScript \
					extensions/CirrusSearch/maintenance/dumpIndex.php \
					--wiki=$wiki \
					--indexType=$type \
					2> /var/log/cirrusdump/cirrusdump-$filename.log \
					| $gzip > $targetFile
			fi
		done
	fi
done

# dump the metastore index (contains persistent states used by cirrus
# administrative tasks). This index is cluster scoped and not bound to a
# particular wiki (we pass --wiki to mwscript because it's mandatory but this
# option is not used by the script itself)
clusters="eqiad codfw"
for cluster in $clusters; do
	filename="cirrus-metastore-$cluster-$today"
	targetFile="$targetDir/$filename.json.gz"
	if [ "$dryrun" == "true" ]; then
		echo "$php $multiVersionScript extensions/CirrusSearch/maintenance/metastore.php --wiki=metawiki --dump --cluster=$cluster 2>> /var/log/cirrusdump/cirrusdump-$filename.log | $gzip > $targetFile"
	else
		$php $multiVersionScript \
			extensions/CirrusSearch/maintenance/metastore.php \
			--wiki=metawiki \
			--dump \
			--cluster=$cluster \
			2>> /var/log/cirrusdump/cirrusdump-$filename.log \
			| $gzip > $targetFile
	fi
done



# Maintain a 'current' symlink always pointing at the most recently completed dump
if [ "$dryrun" == "false" ]; then
	cd "$targetDirBase"
        rm -f "current"
	ln -s "$today" "current"
fi

# clean up old log files
find /var/log/cirrusdump/ -name 'cirrusdump-*.log*' -mtime +22 -delete
