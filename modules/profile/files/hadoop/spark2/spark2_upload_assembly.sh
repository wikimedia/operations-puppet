#!/bin/bash

# Uploads the spark-assembly.zip file to HDFS (as requested by spark-defaults.conf)

spark2_sharelib_dir='/user/spark/share/lib'
spark2_assembly_local_path='/usr/lib/spark2/spark2-assembly.zip'
spark2_assembly_hdfs_path="${spark2_sharelib_dir}/spark2-assembly.zip"

# If the $spark2_sharelib_dir already exists, it doesn't need installed, exit 0.
hdfs dfs -test -e $spark2_assembly_hdfs_path && echo "No need to deploy ${spark2_assembly_local_path} on HDFS, ${spark2_assembly_hdfs_path} already exists." && exit 0

/usr/bin/hdfs dfs -mkdir -p $spark2_sharelib_dir
/usr/bin/hdfs dfs -put $spark2_assembly_local_path $spark2_assembly_hdfs_path