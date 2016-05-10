#!/bin/bash

# Creates a new druid-hdfs-storage-cdh extension by using symlinks
# to merge druid-hdfs-storage.jar and Hadoop client dependencies provided
# by Cloudera CDH in /usr/lib/hadoop/client.

source=${1:-/usr/share/druid/extensions/druid-hdfs-storage}
dest=${2:-/usr/share/druid/extensions/druid-hdfs-storage-cdh}
hadoop=${3:-/usr/lib/hadoop/client}

# Make sure the new extension directory exists.
mkdir -p $dest

# Loop through each jar in the druid-hdfs-storage directory and
# symlink the hadoop equivalents out of the hadoop client directory.
for storage_jar in $source/*.jar; do
    # Strip version from jar.
    base_jar=$(basename $(echo "${storage_jar}" | sed 's@-[0-9\.-]*\.jar$@.jar@'))

    # We need to link to the druid-hdfs-storage jar from the $source directory.
    if [ "${base_jar}" == 'druid-hdfs-storage.jar' ]; then
        ln -sfv $storage_jar ${dest}/
    # Otherwise assume this jar is provided by cdh in /var/lib/hadoop/client.
    # Symlink it into our new extension from here.
    else
        test -f /usr/lib/hadoop/client/$base_jar && ln -sfv /usr/lib/hadoop/client/$base_jar $dest/
    fi
done

# New Hadoop Client also needs htrace-core, but this is not in
# source druid-hdfs-storage extension.  Symlink it explicitly
ln -sfv /usr/lib/hadoop/client/htrace-core4.jar $dest/
