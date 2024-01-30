#!/bin/bash

set -e
set -u

BASE_PATH="${1:-}"
DATE="${2:-$(date +'%F-%H-%M')}"
BACKUP="${BASE_PATH}/psql-all-dbs-${DATE}.sql.gz"
LATEST="${BASE_PATH}/psql-all-dbs-latest.sql.gz"

/usr/bin/pg_dumpall | /bin/gzip > "${BACKUP}" && /usr/bin/ln -f "${BACKUP}" "${LATEST}"
