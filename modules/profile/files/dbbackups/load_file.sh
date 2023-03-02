#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0

# file used for client credentials
CREDENTIALS_FILE="/root/.my.cnf"
# client executable
MYSQL_EXECUTABLE='mysql'
# command line options for the load
mysql_cli="$MYSQL_EXECUTABLE --defaults-file=$CREDENTIALS_FILE"

table="${1%%.sql.gz}";
db="${1%%.*}"

echo "Importing data to table $table..."
$mysql_cli $db && \
    echo "Table $table imported successfully" || { echo "[ERROR] Table $table failed to be imported"; exit 1; }
