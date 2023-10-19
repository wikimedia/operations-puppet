#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
# create a DB backup with mysqldump and compress it
source /etc/community_civicrm/dbdump.cfg
DATESTRING=$(date +%Y%m%d)
"${MYSQLDUMP}" -u root "${DBNAME}" > "${BACKUPDIR}/${DUMPNAME}_${DATESTRING}.sql"
/bin/gzip "${BACKUPDIR}/${DUMPNAME}_${DATESTRING}.sql"
