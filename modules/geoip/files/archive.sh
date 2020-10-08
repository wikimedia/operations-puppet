#!/bin/bash
set -e
MAXMIND_DB_SOURCE_DIR=${1:-"/usr/share/GeoIP"}
HDFS_ARCHIVE_DIR=${2:-"/wmf/data/archive/geoip"}

CURRENT_DATE=$(date +'%Y-%m-%d')

echo "Copying $MAXMIND_DB_SOURCE_DIR into HDFS at $HDFS_ARCHIVE_DIR"

hdfs dfs -mkdir -p "$HDFS_ARCHIVE_DIR/$CURRENT_DATE"
hdfs dfs -put -f $MAXMIND_DB_SOURCE_DIR/* "$HDFS_ARCHIVE_DIR/$CURRENT_DATE/"
