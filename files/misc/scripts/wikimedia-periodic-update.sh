#!/bin/bash
. /usr/local/lib/mw-deployment-vars.sh

for db in `<"$MEDIAWIKI_DEPLOYMENT_DIR/flaggedrevs.dblist"`;do
	echo $db
	php $MEDIAWIKI_DEPLOYMENT_DIR/multiversion/MWScript.php extensions/FlaggedRevs/maintenance/updateStats.php $db
done
