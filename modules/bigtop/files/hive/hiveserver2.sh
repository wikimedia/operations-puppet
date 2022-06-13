#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
#####################################################################
### THIS FILE IS MANAGED BY PUPPET
#####################################################################


THISSERVICE=hiveserver2
export SERVICE_LIST="${SERVICE_LIST}${THISSERVICE} "

hiveserver2() {
  CLASS=org.apache.hive.service.server.HiveServer2
  if $cygwin; then
    HIVE_LIB=`cygpath -w "$HIVE_LIB"`
  fi
  JAR=${HIVE_LIB}/hive-service-[0-9].*.jar

  # Patch not included in standard hive versions:
  # https://issues.apache.org/jira/browse/HIVE-12582
  export HADOOP_OPTS="$HIVE_SERVER2_HADOOP_OPTS $HADOOP_OPTS"
  exec $HADOOP jar $JAR $CLASS $HIVE_OPTS "$@"
}

hiveserver2_help() {
  hiveserver2 -H
}