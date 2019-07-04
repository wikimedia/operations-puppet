#!/bin/bash
set -e
MAXMIND_DB_SOURCE_DIR=${1:-"/usr/share/GeoIP"}
MAXMIND_DB_ARCHIVE_DIR=${2:-"$MAXMIND_DB_SOURCE_DIR/archive"}
HDFS_ARCHIVE_DIR=${3:-"/wmf/data/archive/geoip"}

CURRENT_DATE=$(date +'%Y-%m-%d')

echo "Copying $MAXMIND_DB_SOURCE_DIR to $MAXMIND_DB_ARCHIVE_DIR/$CURRENT_DATE"

mkdir "$MAXMIND_DB_ARCHIVE_DIR/$CURRENT_DATE"
find "$MAXMIND_DB_SOURCE_DIR" -maxdepth 1 -type f -exec cp {} "$MAXMIND_DB_ARCHIVE_DIR/$CURRENT_DATE/" \;

echo "Copying $MAXMIND_DB_ARCHIVE_DIR/$CURRENT_DATE into HDFS at $HDFS_ARCHIVE_DIR"

hdfs dfs -mkdir -p $HDFS_ARCHIVE_DIR
hdfs dfs -put -f "$MAXMIND_DB_ARCHIVE_DIR/$CURRENT_DATE" "$HDFS_ARCHIVE_DIR"
