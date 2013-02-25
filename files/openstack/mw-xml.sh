#!/bin/bash

cd /srv/org/wikimedia/controller/wikis/w
php maintenance/dumpBackup.php --full --uploads | nice -n 19 gzip -9 > /a/backup/public/labswiki-$(date '+%Y%m%d').xml.gz
cd -
