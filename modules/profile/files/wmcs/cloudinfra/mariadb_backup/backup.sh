#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
set -euxo pipefail
DATE=$(date '+%Y%m%d')

for db in "$@"; do
	mariadbdump --master-data=2 --single-transaction "$db" | gzip -9 > /srv/backup/mariadb/backup-"$DATE"-"$db".sql.gz
done
