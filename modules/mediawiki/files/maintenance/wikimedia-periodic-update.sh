#!/bin/bash
. /etc/profile.d/mediawiki.sh

for db in `<"$MEDIAWIKI_DEPLOYMENT_DIR/dblist/flaggedrevs.dblist"`;do
	echo $db
	php $MEDIAWIKI_DEPLOYMENT_DIR/multiversion/MWScript.php extensions/FlaggedRevs/maintenance/updateStats.php $db
done
