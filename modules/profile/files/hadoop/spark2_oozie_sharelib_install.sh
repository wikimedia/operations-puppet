#!/bin/bash

# Installs an 'oozie sharelib' for spark 2 from WMF's spark2 package.
# This roughly follows instructions from:
#  https://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.6.0/bk_spark-component-guide/content/ch_oozie-spark-action.html#spark-config-oozie-spark2


# Ensure that we are running as the oozie user
# if [ $(/usr/bin/whoami) != "oozie" ]; then
#     echo "Cannot build and install spark2 ooziesharelib: must run as oozie user."
#     exit 1
# fi


# Ensure that spark-core (spark 1) is installed so we can use its oozie sharelib jar for spark 2.
dpkg -l spark-core >/dev/null || echo "Cannot build and install spark2 oozie sharelib: spark-core package is not installed." || exit 1

# Ensure that spark2 is installed.
dpkg -l spark2 >/dev/null || echo "Cannot build and install spark2 oozie sharelib: spark2 package is not installed." || exit 1

# Get the currently installed spark2 version from dpkg.
spark2_version=$(dpkg -s spark2 | grep Version | awk -F ': ' '{print $2}' | awk -F '-' '{print $1}')

# Find the (latest) oozie sharelib directory.
sharelib_dir=$(/usr/bin/hdfs dfs -ls -d /user/oozie/share/lib/lib_* | tail -n 1 | awk '{print $NF}')

spark2_sharelib_dir="${sharelib_dir}/spark${spark2_version}"

# If the $spark2_sharelib_dir already exists, it doesn't need installed, exit 0.
hdfs dfs -test -e $spark2_sharelib_dir && echo "No need to build and install spark${spark2_version} oozie sharelib: ${spark2_sharelib_dir} already exists." && exit 0


# Enable verbose command output.
set -x

# Make the spark2 sharelib dir
sudo -u oozie /usr/bin/hdfs dfs -mkdir -p $spark2_sharelib_dir

# Copy spark2 jar files from the spark2 jar directory
sudo -u oozie hdfs dfs -put /usr/lib/spark2/jars/* $spark2_sharelib_dir/

# Copy Python libraries
sudo -u oozie hdfs dfs -put  /usr/lib/spark2/python/lib/py* $spark2_sharelib_dir/

# Copy the oozie-sharelib-spark jar file from the spark 1 oozie sharelib
sudo -u oozie hdfs dfs -put /usr/lib/spark/assembly/lib/spark-assembly*.jar $spark2_sharelib_dir/

# Source oozie.sh to get $OOZIE_URL
test -f /etc/profile.d/oozie.sh && source /etc/profile.d/oozie.sh

sleep 10
# Run the Oozie sharelibupdate command
/usr/bin/oozie admin -oozie $OOZIE_URL –sharelibupdate
