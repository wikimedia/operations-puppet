#!/bin/sh

/usr/local/bin/mwscript maintenance/dumpBackup.php labswiki --current --uploads | sed 's/<model>yaml<\/model>/<model>wikitext<\/model>/g' | sed 's/<format>application\/yaml<\/format>/<format>text\/x-wiki<\/format>/g' | nice -n 19 gzip -9 > /srv/backup/public/labswiki-$(date '+%Y%m%d').xml.gz
