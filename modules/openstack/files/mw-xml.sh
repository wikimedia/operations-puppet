#!/bin/bash

cd /srv/mediawiki/php
/usr/local/bin/mwscript maintenance/dumpBackup.php labswiki --current --uploads | nice -n 19 gzip -9 > /a/backup/public/labswiki-$(date '+%Y%m%d').xml.gz
cd -
