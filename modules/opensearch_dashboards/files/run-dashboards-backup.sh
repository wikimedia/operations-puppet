#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
# Manages backups from the saved objects export api.

set -e

if [ $(whoami) != 'opensearch-dashboards' ]; then
  echo "Script must be run as opensearch-dashboards user: sudo -u opensearch-dashboards ${0}"
  exit 1
fi

OUTFILE=export_$(date +%Y%m%d).ndjson
URL="http://localhost:5601/api/saved_objects/_export"
BODY='{"type":["index-pattern","url","search","visualization","dashboard","config","query"],"includeReferencesDeep":true}'
BACKUPDIR='/srv/backups/opensearch_dashboards'

curl -s -X POST ${URL} -H 'Content-Type: application/json' -H 'osd-xsrf: true' -d ${BODY} -o ${BACKUPDIR}/${OUTFILE}

gzip ${BACKUPDIR}/${OUTFILE}

# Clean up old backups
find ${BACKUPDIR} -type f -mtime +30 -delete

# Copy latest backup to a predictable name for off-host backups
# This cannot be a symlink
cp ${BACKUPDIR}/${OUTFILE}.gz ${BACKUPDIR}/export_latest.ndjson.gz
