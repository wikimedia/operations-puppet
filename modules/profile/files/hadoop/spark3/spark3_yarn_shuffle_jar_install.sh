#!/bin/bash
# SPDX-License-Identifier: Apache-2.0

#
# Removes the spark2-yarn-shuffle.jar symlink from /usr/lib/hadoop-yarn/lib and then
# creates another symlink to the version in /usr/lib/spark3/jars
#

yarn_lib_dir='/usr/lib/hadoop-yarn/lib'

spark3_yarn_shuffle_jar=$(find /usr/lib/spark3/yarn -name 'spark*yarn-shuffle.jar' | head -n 1)

if [ ! -f $spark3_yarn_shuffle_jar ]; then
    echo 'Cannot install spark3-yarn-shuffle.jar: no yarn shuffle jar found in /usr/lib/spark3/yarn.'
    exit 1
fi

# If the symlink to the spark2-yarn-shuffler jar exists, delete it.
if [ -L $yarn_lib_dir/spark2-yarn-shuffle.jar ]; then
    rm $yarn_lib_dir/spark2-yarn-shuffle.jar
fi

# If the version spark3-yarn-shuffle.jar already points at the currently installed version
# of Spark 3's spark yarn shuffle jar, then we don't need to do anything else.
if [ $spark3_yarn_shuffle_jar -ef $yarn_lib_dir/spark3-yarn-shuffle.jar ]; then
    echo "No need to install spark3-yarn-shuffle.jar symlink it already points at $spark3_yarn_shuffle_jar."
    exit 0
fi

echo "Symlinking $spark3_yarn_shuffle_jar to $yarn_lib_dir/spark3-yarn-shuffle.jar"
ln -sfv $spark3_yarn_shuffle_jar $yarn_lib_dir/spark3-yarn-shuffle.jar
