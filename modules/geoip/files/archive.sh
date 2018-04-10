#!/bin/bash
set -e
MAXMIND_DB_SOURCE_DIR=${1:-"/usr/share/GeoIP"}
MAXMIND_DB_ARCHIVE_DIR=${2:-"$MAXMIND_DB_SOURCE_DIR/archive"}
HDFS_ARCHIVE_DIR=${3:-"/wmf/data/archive/geoip"}

CURRENT_DATE=$(date +'%Y-%m-%d')

# hardlinking to avoid duplicating too much data
cp -rl "$MAXMIND_DB_SOURCE_DIR/." "$MAXMIND_DB_ARCHIVE_DIR/$CURRENT_DATE"

hdfs dfs -mkdir -p $HDFS_ARCHIVE_DIR
hdfs dfs -put -f "$MAXMIND_DB_ARCHIVE_DIR/$CURRENT_DATE" "$HDFS_ARCHIVE_DIR"
