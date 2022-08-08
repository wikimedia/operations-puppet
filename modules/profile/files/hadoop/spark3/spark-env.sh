#!/usr/bin/env bash

# NOTE: This file is managed by Puppet.

#
# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# This file is sourced when running various Spark programs.
# Copy it as spark-env.sh and edit that to configure Spark for your site.

# Options read when launching programs locally with
# ./bin/run-example or ./bin/spark-submit
# - HADOOP_CONF_DIR, to point Spark towards Hadoop configuration files
# - SPARK_LOCAL_IP, to set the IP address Spark binds to on this node
# - SPARK_PUBLIC_DNS, to set the public dns name of the driver program
# - SPARK_CLASSPATH, default classpath entries to append

# Options read by executors and drivers running inside the cluster
# - SPARK_LOCAL_IP, to set the IP address Spark binds to on this node
# - SPARK_PUBLIC_DNS, to set the public DNS name of the driver program
# - SPARK_CLASSPATH, default classpath entries to append
# - SPARK_LOCAL_DIRS, storage directories to use on this node for shuffle and RDD data
# - MESOS_NATIVE_JAVA_LIBRARY, to point to your libmesos.so if you use Mesos

# Options read in YARN client mode
# - HADOOP_CONF_DIR, to point Spark towards Hadoop configuration files
# - SPARK_EXECUTOR_INSTANCES, Number of executors to start (Default: 2)
# - SPARK_EXECUTOR_CORES, Number of cores for the executors (Default: 1).
# - SPARK_EXECUTOR_MEMORY, Memory per Executor (e.g. 1000M, 2G) (Default: 1G)
# - SPARK_DRIVER_MEMORY, Memory for Driver (e.g. 1000M, 2G) (Default: 1G)

# Options for the daemons used in the standalone deploy mode
# - SPARK_MASTER_HOST, to bind the master to a different IP address or hostname
# - SPARK_MASTER_PORT / SPARK_MASTER_WEBUI_PORT, to use non-default ports for the master
# - SPARK_MASTER_OPTS, to set config properties only for the master (e.g. "-Dx=y")
# - SPARK_WORKER_CORES, to set the number of cores to use on this machine
# - SPARK_WORKER_MEMORY, to set how much total memory workers have to give executors (e.g. 1000m, 2g)
# - SPARK_WORKER_PORT / SPARK_WORKER_WEBUI_PORT, to use non-default ports for the worker
# - SPARK_WORKER_INSTANCES, to set the number of worker processes per node
# - SPARK_WORKER_DIR, to set the working directory of worker processes
# - SPARK_WORKER_OPTS, to set config properties only for the worker (e.g. "-Dx=y")
# - SPARK_DAEMON_MEMORY, to allocate to the master, worker and history server themselves (default: 1g).
# - SPARK_HISTORY_OPTS, to set config properties only for the history server (e.g. "-Dx=y")
# - SPARK_SHUFFLE_OPTS, to set config properties only for the external shuffle service (e.g. "-Dx=y")
# - SPARK_DAEMON_JAVA_OPTS, to set config properties for all daemons (e.g. "-Dx=y")
# - SPARK_PUBLIC_DNS, to set the public dns name of the master or workers

# Generic options for the daemons used in the standalone deploy mode
# - SPARK_CONF_DIR      Alternate conf dir. (Default: ${SPARK_HOME}/conf)
# - SPARK_LOG_DIR       Where log files are stored.  (Default: ${SPARK_HOME}/logs)
# - SPARK_PID_DIR       Where the pid file is stored. (Default: /tmp)
# - SPARK_IDENT_STRING  A string representing this instance of spark. (Default: $USER)
# - SPARK_NICENESS      The scheduling priority for daemons. (Default: 0)
# - SPARK_NO_DAEMONIZE  Run the proposed command in the foreground. It will not output a PID file.

# Custom WMF options:
# - CONDA_BASE_ENV_PREFIX If conda is active and we are running in YARN, this will be used as the default PYSPARK_PYTHON (default: /usr/lib/anaconda-wmf)

# If /etc/hadoop/conf exists, use it as HADOOP_CONF_DIR
if [ -z "${HADOOP_CONF_DIR}" -a -e "/etc/hadoop/conf" ]; then
  export HADOOP_CONF_DIR=/etc/hadoop/conf
fi

# If hadoop command is executable, then use it to add Hadoop jars to Spark's runtime classpath.
# See: https://spark.apache.org/docs/2.4.4/hadoop-provided.html
#
# TODO: Uncomment when we use a Spark3 that doesn't embed Hadoop
#       For now we use the Airflow-installed version of Spark3 that
#       embeds Hadoop 3.2.0
#
#if [ -x "$(command -v hadoop)" ]; then
#    SPARK_DIST_CLASSPATH=$(hadoop classpath)
#fi

# If /usr/lib/hadoop/native exists, use Hadoop native libs from there
if [ -z "${LD_LIBRARY_PATH}" -a -e /usr/lib/hadoop/lib/native ]; then
    export LD_LIBRARY_PATH=/usr/lib/hadoop/lib/native
fi

# TODO: Fix environment variables for pyspark (commented for now)

#: ${CONDA_BASE_ENV_PREFIX:='/usr/lib/anaconda-wmf'}

# Default PYSPARK_DRIVER_PYTHON to ipython if running pyspark CLI directly.
#if [[ -z "${PYSPARK_DRIVER_PYTHON}" && "${0}" == *pyspark* ]]; then
#    # If a conda environment is active, then use its ipython3.
#    if [ -n "${CONDA_PREFIX}" -a -e "${CONDA_PREFIX}/bin/ipython3" ]; then
#        export PYSPARK_DRIVER_PYTHON="$(realpath ${CONDA_PREFIX}/bin/ipython3)"
#    # TODO: default to always using anaconda-wmf for pyspark, even if a conda env is not active.
#    # Else if CONDA_BASE_ENV_PREFIX exists, then use its ipython3
#    # elif [ -n "${CONDA_BASE_ENV_PREFIX}" -a -e "${CONDA_BASE_ENV_PREFIX}/bin/ipython3" ]; then
#    #     export PYSPARK_DRIVER_PYTHON="$(realpath ${CONDA_BASE_ENV_PREFIX}/bin/ipython3)"
#    # Else is ipython3 is somewhere in PATH, use it.
#    elif [ -n "$(command -v ipython3)" ]; then
#        export PYSPARK_DRIVER_PYTHON="$(realpath $(command -v ipython3))"
#    fi
#fi

# If running in yarn and a conda env is active and CONDA_BASE_ENV_PREFIX exists,
# then default to using CONDA_BASE_ENV_PREFIX for PYSPARK_PYTHON.
# Since CONDA_BASE_ENV_PREFIX should be installed on all remote YARN workers,
# this should allow pyspark to work. If you need custom python depdendencies on
# remote workers, you'll have to pack up a custom conda env and
# set PYSPARK_PYTHON accordingly.
# TODO: always use CONDA_BASE_ENV_PREFIX even if a conda env is not currently active.
#if [ -z "${PYSPARK_PYTHON}" ]; then
    # Search the CLI opts to find the master option, if it is given.
    # PYSPARK_PYTHON needs to be set to something that will work on remote executors
    # if a conda environment is active.  This will only work if
    # the SparkSession master is being set via the CLI.
#    spark_master=''
#    for #((i = 1; i <= $#; i++ )); do
#        arg="${!i}"
#        if [[ "${arg}" == --master ]]; then
#            master_index=$((i+1))
#            spark_master="${!master_index}"
#        elif [[ "${arg}" == --master=* ]]; then
#            spark_master="$(echo ${arg} | cut -f2 -d=)"
#        fi
#    done

    # TODO: remove the -n $CONDA_PREFIX check and always default to CONDA_BASE_ENV_PREFIX/bin/python3.
#    if [[ "${spark_master}" == yarn* && -n "${CONDA_PREFIX}" && -e "${CONDA_BASE_ENV_PREFIX}/bin/python3" ]] ; then
#        export PYSPARK_PYTHON="$(realpath ${CONDA_BASE_ENV_PREFIX}/bin/python3)"
#    elif [ -z "${CONDA_PREFIX}" -a -n "$(command -v python3)" ]; then
        # If using the system python3, set PYSPARK_PYTHON to default to the versioned python
        # executable on the node where spark is being launched.
        # E.g. on Stretch we want python3.5 and on Buster we want python3.7.
        # This will cause the versions of python that is used on driver
        # and on workers to be the same.
        # https://phabricator.wikimedia.org/T229347#5439259
        # TODO: Remove this once we always default to CONDA_BASE_ENV_PREFIX/bin/python3
##        export PYSPARK_PYTHON="$(basename $(realpath $(command -v python3)))"
        # If SPARK_HOME/pythonX.X exists, then insert it into the front of PYTHONPATH
        # So any provided packages override system installed ones.
#        python_version_path=${SPARK_HOME}/$(${PYSPARK_PYTHON} -c 'import sys; print("python{}.{}".format(sys.version_info.major, sys.version_info.minor))')
#        if [ -d "${python_version_path}" ]; then
#            export PYTHONPATH="${python_version_path}:${PYTHONPATH}"
#        fi
#    fi
#fi

# Note: If PYSPARK_DRIVER_PYTHON and PYSPARK_PYTHON are not set at this point,
# the pyspark script will just use 'python'.
#test -n "${PYSPARK_DRIVER_PYTHON}" && echo "PYSPARK_DRIVER_PYTHON=$PYSPARK_DRIVER_PYTHON"
#test -n "${PYSPARK_PYTHON}" && echo "PYSPARK_PYTHON=$PYSPARK_PYTHON"
