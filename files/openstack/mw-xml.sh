#!/bin/bash

cd /srv/mediawiki/php
php maintenance/dumpBackup.php --full --uploads | nice -n 19 gzip -9 > /a/backup/public/labswiki-$(date '+%Y%m%d').xml.gz
cd -
