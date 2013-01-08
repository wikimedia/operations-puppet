#!/bin/bash
. /usr/local/lib/mw-deployment-vars.sh

for db in `<"$MW_DBLISTS/flaggedrevs.dblist"`;do
	echo $db
	php $MW_COMMON/multiversion/MWScript.php extensions/FlaggedRevs/maintenance/updateStats.php $db
done
