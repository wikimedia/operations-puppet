#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0

# requirements:
# apt install mariadb-client-10.5 pigz parallel

# Command used to decompress the files
DECOMPRESS_COMMAND="pigz -c -d"
# Number of parallel jobs
NJOBS=16
# file used for client credentials
CREDENTIALS_FILE="/root/.my.cnf"
# client executable
MYSQL_EXECUTABLE='mysql'
# command line options for the load
MYSQL_CLI="$MYSQL_EXECUTABLE --defaults-file=$CREDENTIALS_FILE"
# command run to send data to its standard input
LOAD_FILE="/usr/bin/load_file.sh"

# Check input arguments
if [ -z "$1" ]; then
    echo "[ERROR] At least one argument (the dump directory) has to be provided"
    exit 255
fi

# Check that credentials file exists
if [ ! -f "$CREDENTIALS_FILE" ]; then
    echo "[ERROR] There is no $CREDENTIALS_FILE file in the current directory"
    exit 1
fi

cd "$1" || { echo "[ERROR] We couldn't cd into the $1 directory"; exit 2; }

echo "Starting recovery at $(date --rfc-3339=seconds)"

# Database creation: Iterate over all files ending in "-schema-create.sql.gz"
find . -type f -name '*-schema-create.sql.gz' -printf '%f\n' | while read db_schema_file; do
    db="${db_schema_file%%-schema-create.sql.gz}"
    echo "Creating database $db..."
    ( echo "SET sql_log_bin = OFF;"; $DECOMPRESS_COMMAND $db_schema_file ) | $MYSQL_CLI && \
        echo "Database $db created successfully" || \
        { echo "[ERROR] Database $db failed to be created"; exit 3; }
done

# Table creation: Iterate over all files ending in "-schema.sql.gz"
find . -type f -name '*-schema.sql.gz' -printf '%f\n' | while read table_schema_file; do
    table="${table_schema_file%%-schema.sql.gz}"
    db="${table%%.*}"
    echo "Creating table $table..."
    ( echo "SET sql_log_bin = OFF;"; $DECOMPRESS_COMMAND $table_schema_file ) | $MYSQL_CLI $db && \
        echo "Table $table created successfully" || \
        { echo "[ERROR] Table $table failed to be created"; exit 4; }
done

# Table load: Iterate over all files ending in ".sql.gz" that do not end in "-schema-create.sql.gz" or "-schema.sql.gz",
# load them in parallel
find . -type f \! -name '*-schema-create.sql.gz' \! -name '*-schema.sql.gz' -name '*.sql.gz' -printf '%s %f\n' |
    sort -nr |
    cut -d' ' -f2- |
    parallel -j$NJOBS -a - "(echo \"SET sql_log_bin = OFF; SET sql_mode = ''; START TRANSACTION; \" ; $DECOMPRESS_COMMAND {}; echo \"COMMIT;\") | $LOAD_FILE {}" || exit 1

# Trigger creation: Iterate over all files ending in "-schema-triggers.sql.gz"
find . -type f -name '*-schema-triggers.sql.gz' -printf '%f\n' | while read triggers_schema_file; do
    table="${triggers_schema_file%%-schema-triggers.sql.gz}"
    db="${table%%.*}"
    echo "Creating triggers for $table..."
    ( echo "SET sql_log_bin = OFF;"; $DECOMPRESS_COMMAND $triggers_schema_file ) | $MYSQL_CLI $db && \
        echo "Triggers for $table created successfully" || \
        { echo "[ERROR] Triggers for $table failed to be created"; exit 5; }
done

# View creation: Iterate over all files ending in "-schema-view.sql.gz"
find . -type f -name '*-schema-view.sql.gz' -printf '%f\n' | while read view_schema_file; do
    view="${view_schema_file%%-schema-view.sql.gz}"
    db="${view%%.*}"
    echo "Creating triggers for $table..."
    ( echo "SET sql_log_bin = OFF;"; $DECOMPRESS_COMMAND $view_schema_file ) | $MYSQL_CLI $db && \
        echo "View $view created successfully" || \
        { echo "[ERROR] View $view failed to be created"; exit 6; }
done

# Stored procedures, functions and events: Iterate over all files ending in "-schema-post.sql.gz"
find . -type f -name '*-schema-post.sql.gz' -printf '%f\n' | while read procs_schema_file; do
    db="${procs_schema_file%%-schema-post.sql.gz}"
    echo "Creating procedures, functions and events in $db..."
    ( echo "SET sql_log_bin = OFF;"; $DECOMPRESS_COMMAND $procs_schema_file ) | $MYSQL_CLI $db && \
        echo "Procedures, functions and events in $db created successfully" || \
        { echo "[ERROR] Procedures, functions and events in $db failed to be created"; exit 7; }
done

echo "Finishing recovery at $(date --rfc-3339=seconds)"
echo "Remember to remove $CREDENTIALS_FILE to prevent accidental loads"
