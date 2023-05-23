#!/bin/bash
# SPDX-License-Identifier: Apache-2.0

#
# Removes all Spark 1 and 2 spark-*yarn-shuffle.jar from /usr/lib/hadoop-yarn/lib and then
# symlinks the one from /usr/lib/spark3/jars into /usr/lib/hadoop-yarn/lib
#

yarn_lib_dir='/usr/lib/hadoop-yarn/lib'
yarn_lib_removed_dir='/usr/lib/hadoop-yarn/lib.removed'

spark3_yarn_shuffle_jar=$(find /usr/lib/spark3/yarn -name 'spark*yarn-shuffle.jar' | head -n 1)

if [ ! -f $spark3_yarn_shuffle_jar ]; then
    echo 'Cannot install spark3-yarn-shuffle.jar: no yarn shuffle jar found in /usr/lib/spark3/yarn.'
    exit 1
fi

# If the version spark3-yarn-shuffle.jar already points at the currently installed version
# of Spark 3's spark yarn shuffle jar, then we don't need to do anything else.
if [ $spark3_yarn_shuffle_jar -ef $yarn_lib_dir/spark3-yarn-shuffle.jar ]; then
    echo "No need to install spark3-yarn-shuffle.jar symlink it already points at $spark3_yarn_shuffle_jar."
    exit 0
fi

# Create a  README file and directory in which to store removed jar files.
if [ ! -f $yarn_lib_removed_dir/README ]; then
    mkdir -p $yarn_lib_removed_dir
    echo "Files here were originally in $yarn_lib_dir, but have been moved so they no longer are loaded by YARN" > $yarn_lib_removed_dir/README
fi


echo "Moving YARN Spark 2 spark yarn shuffle jar(s) out of $yarn_lib_dir"
mv -v $yarn_lib_dir/spark-*yarn-shuffle.jar $yarn_lib_removed_dir/

echo "Symlinking $spark3_yarn_shuffle_jar to $yarn_lib_dir/spark3-yarn-shuffle.jar"
ln -sfv $spark3_yarn_shuffle_jar $yarn_lib_dir/spark3-yarn-shuffle.jar
