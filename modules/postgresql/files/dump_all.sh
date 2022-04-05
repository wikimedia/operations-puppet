#!/bin/bash

set -e
set -u

path=${1:-}
date=${2:-}

/usr/bin/pg_dumpall | \
/bin/gzip > ${path}/psql-all-dbs-${date}.sql.gz
