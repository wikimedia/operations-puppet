#!/bin/bash

# Installs an 'oozie sharelib' for spark 2 from WMF's spark2 package.
# This roughly follows instructions from:
#  https://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.6.0/bk_spark-component-guide/content/ch_oozie-spark-action.html#spark-config-oozie-spark2


function die {
    message="${1}"
    echo "Cannot build and install spark2 ooziesharelib: ${message}."
    exit 1
}


# Ensure that we are running as the oozie user
if [ $(/usr/bin/whoami) != "oozie" ]; then
    die "must run as oozie user"
    exit 1
fi

# Source oozie.sh to get $OOZIE_URL
/usr/bin/test -f /etc/profile.d/oozie.sh && source /etc/profile.d/oozie.sh
test -n "${OOZIE_URL}" || die "must set \$OOZIE_URL to talk to Oozie server"

# Ensure that spark-core (spark 1) is installed so we can use its oozie sharelib jar for spark 2.
dpkg -l spark-core >/dev/null || die "spark-core package is not installed"

# Ensure that spark2 is installed.
dpkg -l spark2 >/dev/null || die "spark2 package is not installed"

# Get the currently installed spark2 version from dpkg.
spark2_version=$(dpkg -s spark2 | grep Version | awk -F ': ' '{print $2}' | awk -F '-' '{print $1}')

spark2_sharelib="spark${spark2_version}"

# Find the (latest) oozie sharelib directory.
sharelib_dir=$(/usr/bin/hdfs dfs -ls -d /user/oozie/share/lib/lib_* | tail -n 1 | awk '{print $NF}')

spark2_sharelib_dir="${sharelib_dir}/${spark2_sharelib}"

# If the $spark2_sharelib_dir already exists, it doesn't need installed, exit 0.
hdfs dfs -test -e $spark2_sharelib_dir && echo "No need to build and install ${spark2_sharelib} oozie sharelib: ${spark2_sharelib_dir} already exists." && exit 0



# Enable verbose command output.
set -x

# copy current sharelib to new sharelib dir
# hdfs dfs -cp $curr_sharelib_dir $new_sharelib_dir

# Make the spark2 sharelib dir
/usr/bin/hdfs dfs -mkdir -p $spark2_sharelib_dir

# Copy spark2 jar files from the spark2 jar directory
/usr/bin/hdfs dfs -put /usr/lib/spark2/jars/* $spark2_sharelib_dir/

# Copy Python libraries
/usr/bin/hdfs dfs -put  /usr/lib/spark2/python/lib/py* $spark2_sharelib_dir/

# Copy the oozie-sharelib-spark jar file from the spark 1 oozie sharelib
/usr/bin/hdfs dfs -put /usr/lib/oozie/oozie-sharelib-yarn/lib/spark/oozie-sharelib-spark*.jar $spark2_sharelib_dir/

# Copy hive-site.xml (assumes this exists in /user/hive)
/usr/bin/hdfs dfs -test -e /user/hive/hive-site.xml && /usr/bin/hdfs dfs -cp /user/hive/hive-site.xml $spark2_sharelib_dir/ || echo "Warning: could not install hive-site.xml into ${spark2_sharelib_dir}.  You might have to do this manually."

# For unknown reasons, oozie admin -sharelibupdate is really flaky.
# Sometimes it succeeds, sometimes it does nothing. We use the Oozie REST API
# directly instead.
/usr/bin/curl $OOZIE_URL/v2/admin/update_sharelib | jq .
/usr/bin/oozie admin -shareliblist | grep -q $spark2_sharelib || \
    echo "${spark2_sharelib} was built but flaky \`oozie admin –sharelibupdate\` did not not work as expected. This will require some manual intervention!"

