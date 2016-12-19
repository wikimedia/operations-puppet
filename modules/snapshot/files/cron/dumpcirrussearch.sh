#!/bin/bash
#############################################################
# This file is maintained by puppet!
# modules/snapshot/cron/dumpcirrussearch.sh
#############################################################
#
# Generate a json dump of cirrussearch indices for all enabled
# wikis and remove old ones.

source /usr/local/etc/set_dump_dirs.sh

usage() {
	echo "Usage: $0 [--config <pathtofile>] [--dryrun]"
	echo
	echo "  --config  path to configuration file for dump generation"
	echo "            (default value: ${confsdir}/wikidump.conf"
	echo "  --dryrun  don't run dump, show what would have been done"
	exit 1
}

configFile="${confsdir}/wikidump.conf"
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

deployDir=$(egrep "^dir=" "$configFile" | mawk -Fdir= '{ print $2 }')
gzip=$(egrep "^gzip=" "$configFile" | mawk -Fgzip= '{ print $2 }')
allList=$(egrep "^dblist=" "$configFile" | mawk -Fdblist= '{ print $2 }')
privateList=$(egrep "^privatelist=" "$configFile" | mawk -Fprivatelist= '{ print $2 }')
publicDir=$(egrep "^public=" "$configFile" | mawk -Fpublic= '{ print $2 }')

if [ -z "$deployDir" -o -z "$gzip" -o -z "$allList" -o -z "$privateList" -o -z "$publicDir" ]; then
	echo "failed to find value of one of the following from config file $configFile:"
	echo "gzip: $gzip"
	echo "dir: $deployDir"
	echo "dblist: $allList"
	echo "privatelist: $privateList"
	echo "public: $publicDir"
	echo "exiting..."
	exit 1
fi

today=$(date +'%Y%m%d')
targetDirBase="$publicDir/other/cirrussearch"
targetDir="$targetDirBase/$today"
multiVersionScript="$deployDir/multiversion/MWScript.php"

# remove old datasets
daysToKeep=70
cutOff=$(( $(date +%s) - $(( $daysToKeep + 1 )) * 24 * 3600))
if [ -d "$targetDirBase" ]; then
	for folder in $(ls -d -r $targetDirBase/*); do
		creationTime=$(date --utc --date="$(basename $folder)" +%s 2>/dev/null)
		if [ -n "$creationTime" ]; then
		    if [ "$cutOff" -gt "$creationTime" ]; then
			if [ "$dryrun" == "true" ]; then
				echo rm $folder/*.json.gz
				echo rmdir $folder
			else
				rm -f $folder/*.json.gz
				rmdir $folder
			fi
		    fi
		fi
	done
fi

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
				echo "php $multiVersionScript extensions/CirrusSearch/maintenance/dumpIndex.php --wiki=$wiki --indexType=$type 2> /var/log/cirrusdump/cirrusdump-$filename.log | $gzip > $targetFile"
			else
				php $multiVersionScript \
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
		echo "php $multiVersionScript extensions/CirrusSearch/maintenance/metastore.php --wiki=metawiki --dump --cluster=$cluster 2>> /var/log/cirrusdump/cirrusdump-$filename.log | $gzip > $targetFile"
	else
		php $multiVersionScript \
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
