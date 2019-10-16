#!/bin/bash

# Uploads the current spark2 version's assembly file to HDFS.
# This file is used as the value of spark.yarn.archive in spark-defaults.conf.

# Get the currently installed spark2 version from dpkg.
spark2_version=$(dpkg-query -W -f='${Version}' spark2 | awk -F '-' '{print $1}')

spark2_sharelib_dir='/user/spark/share/lib'
spark2_assembly_local_path="/usr/lib/spark2/spark-${spark2_version}-assembly.zip"
spark2_assembly_hdfs_path="${spark2_sharelib_dir}/spark-${spark2_version}-assembly.zip"

# If the $spark2_sharelib_dir already exists, it doesn't need installed, exit 0.
hdfs dfs -test -e $spark2_assembly_hdfs_path && echo "No need to deploy ${spark2_assembly_local_path} on HDFS, ${spark2_assembly_hdfs_path} already exists." && exit 0

/usr/bin/hdfs dfs -mkdir -p $spark2_sharelib_dir
/usr/bin/hdfs dfs -put $spark2_assembly_local_path $spark2_assembly_hdfs_path
