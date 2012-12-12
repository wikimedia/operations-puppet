#!/bin/bash
for db in `</home/wikipedia/common/flaggedrevs.dblist`;do
	echo $db
	php -n /home/wikipedia/common/multiversion/MWScript.php extensions/FlaggedRevs/maintenance/updateStats.php $db
done
