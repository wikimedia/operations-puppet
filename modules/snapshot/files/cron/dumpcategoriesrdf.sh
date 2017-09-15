#!/bin/bash
#############################################################
# This file is maintained by puppet!
# modules/snapshot/cron/dumpcategoriesrdf.sh
#############################################################
#
# Generate an RDF dump of categories for all wikis in
# categories-rdf list and remove old ones.

dumpFormat="ttl"

. /usr/local/bin/dumpcategoriesrdf-shared.sh

targetDirBase="${categoriesDirBase}"
targetDir="${targetDirBase}/${today}"

# remove old datasets
daysToKeep=70
fileSuffix="${dumpFormat}.gz"

pruneOldDirs
createFolder

# iterate over configured wikis
cat "$dbList" | while read wiki; do
	# exclude all private wikis
	if ! egrep -q "^${wiki}$" "$privateList"; then
		filename="${wiki}-${today}-categories"
		targetFile="${targetDir}/${filename}.${fileSuffix}"
		tsFile="${timestampsDir}/${wiki}-categories.last"
		if [ "$dryrun" == "true" ]; then
			echo "php $multiVersionScript maintenance/dumpCategoriesAsRdf.php --wiki=$wiki --format=$dumpFormat 2> /var/log/categoriesrdf/${filename}.log | $gzip > $targetFile"
			echo "Timestamp: $ts > $tsFile"
		else
			php "$multiVersionScript" maintenance/dumpCategoriesAsRdf.php --wiki="$wiki" --format="$dumpFormat" 2> "/var/log/categoriesrdf/${filename}.log" | "$gzip" > "$targetFile"
			echo "$ts" > "$tsFile"
		fi
	fi
done

makeLatestLink
