#!/bin/bash
set -e
MAXMIND_DB_SOURCE_DIR=${1:"/usr/lib/GeoIP"}
MAXMIND_DB_ARCHIVE_DIR=${2:"$MAXMIND_DB_SOURCE_DIR/archive"}
HDFS_ARCHIVE_DIR=${3:"/wmf/data/archive/geoip"}

CURRENT_DATE=$(date +'%Y-%m-%d')

cp -RL "$HDFS_ARCHIVE_DIR/." "$MAXMIND_DB_ARCHIVE_DIR/$CURRENT_DATE"

# does /wmf/data/archive/geoip exist in hdfs?
if [ ! $(hdfs dfs -test -d "$HDFS_ARCHIVE_DIR")]
# copy the last directory (the one just created) to the directory structure in hdfs
then
	hdfs dfs -mkdir $HDFS_ARCHIVE_DIR
fi
hdfs dfs -put "$MAXMIND_DB_ARCHIVE_DIR/$CURRENT_DATE" "$HDFS_ARCHIVE_DIR"
