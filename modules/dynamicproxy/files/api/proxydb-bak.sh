#!/bin/bash
set -euxo pipefail

DATE=$(date '+%Y%m%d')

nice -n 19 mariadbdump --single-transaction "$1" | nice -n 19 gzip -9 > /srv/backup/proxy-${HOSTNAME}-${DATE}.sql.gz
