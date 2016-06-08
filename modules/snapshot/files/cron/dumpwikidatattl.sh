#!/bin/bash
#############################################################
# This file is maintained by puppet!
# puppet:///modules/snapshot/cron/dumpwikidatattl.sh
##############################################################
#
# Generate a json dump for Wikidata and remove old ones.
#
# Marius Hoch < hoo@online.de >

. /usr/local/bin/wikidatadumps-shared.sh

filename=wikidata-$today-all-BETA
targetFileGzip=$targetDir/$filename.ttl.gz
targetFileBzip2=$targetDir/$filename.ttl.bz2
failureFile=/tmp/dumpwikidatattl-failure

i=0
shards=4

# Try to create the dump (up to three times).
retries=0

while true; do
	rm -f $failureFile

	while [ $i -lt $shards ]; do
		(
			set -o pipefail
			php $multiversionscript extensions/Wikidata/extensions/Wikibase/repo/maintenance/dumpRdf.php --wiki wikidatawiki --shard $i --sharding-factor $shards --format ttl 2>> /var/log/wikidatadump/dumpwikidatattl-$filename-$i.log | gzip > $tempDir/wikidataTTL.$i.gz
			if [ $? -gt 0 ]; then
				echo 1 > $failureFile
			fi
		) &
		let i++
	done

	wait

	if [ -f $failureFile ]; then
		# Something went wrong, let's clean up and maybe retry. Leave logs in place.
		rm -f $failureFile
		rm $tempDir/wikidataTTL.*.gz
		let retries++

		if [ $retries -eq 3 ]; then
			exit 1
		fi

		# Another attempt
		continue
	fi

	break

done

i=0
while [ $i -lt $shards ]; do
	cat $tempDir/wikidataTTL.$i.gz >> $tempDir/wikidataTtl.gz
	rm $tempDir/wikidataTTL.$i.gz
	let i++
done

mv $tempDir/wikidataTtl.gz $targetFileGzip

gzip -dc $targetFileGzip | bzip2 -c > $tempDir/wikidataTtl.bz2
mv $tempDir/wikidataTtl.bz2 $targetFileBzip2

pruneOldDirectories
pruneOldLogs
runDcat
