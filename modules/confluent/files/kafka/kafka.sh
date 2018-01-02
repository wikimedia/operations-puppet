#!/bin/bash

# NOTE: This file is managed by Puppet.

SCRIPT_NAME=$(basename "$0")

commands=$(ls /usr/bin/kafka-* | xargs -n 1 basename | sed 's@kafka-@  @g')

USAGE="
$SCRIPT_NAME <command> [options]

Handy wrapper around various kafka-* scripts.  Set the environment variables
KAFKA_ZOOKEEPER_URL, KAFKA_BOOTSTRAP_SERVERS so you don't have to keep typing
--zookeeper-connect, --broker-list or --bootstrap-server each time you want to
use a kafka-* script.

Usage:

Run $SCRIPT_NAME <command> with zero arguments/options to see command usage.

Commands:
$commands

Environment Variables:
  KAFKA_JAVA_HOME         - Value of JAVA_HOME to use for invoking Kafka commands.
  KAFKA_ZOOKEEPER_URL     - If this is set, any commands that take a --zookeeper
                            flag will be given this value.
  KAFKA_BOOTSTRAP_SERVERS - If this is set, any commands that take a --broker-list or
                            --bootstrap-server flag will be given this value.
                            Also any command that take a --authorizer-properties
                            will get the correct zookeeper.connect value.

"

# Print usage if no <command> given, or $1 starts with '-'
if [ -z "${1}" -o "${1:0:1}" == '-' ]; then
    echo "${USAGE}"
    exit 1
fi

# All kafka scripts start with kafka-.
command="kafka-${1}"
shift

# Export JAVA_HOME as KAFKA_JAVA_HOME if it is set.
# This makes kafka-run-class use the preferred JAVA_HOME for Kafka.
if [ -n "${KAFKA_JAVA_HOME}" ]; then
    : ${JAVA_HOME="$KAFKA_JAVA_HOME"}
    export JAVA_HOME
fi

# Set ZOOKEEPER_OPT if ZOOKEEPER_URL is set and --zookeeper has not
# also been passed in as a CLI arg.  This will be included
# in command functions that take a --zookeeper argument.
if [ -n "${KAFKA_ZOOKEEPER_URL}" -a -z "$(echo $@ | grep -- --zookeeper)" ]; then
    ZOOKEEPER_OPT="--zookeeper ${KAFKA_ZOOKEEPER_URL}"
fi

# Set BROKER_LIST_OPT if KAFKA_BOOTSTRAP_SERVERS is set and --broker-list has not
# also been passed in as a CLI arg.  This will be included
# in command functions that take a --broker-list argument.
if [ -n "${KAFKA_BOOTSTRAP_SERVERS}" -a -z "$(echo $@ | grep -- --broker-list)" ]; then
    BROKER_LIST_OPT="--broker-list ${KAFKA_BOOTSTRAP_SERVERS}"
fi

# Set BOOTSTRAP_SERVER_OPT if KAFKA_BOOTSTRAP_SERVERS is set and --bootstrap-server has not
# also been passed in as a CLI arg.  This will be included
# in command functions that take a --bootstrap-server argument.
if [ -n "${KAFKA_BOOTSTRAP_SERVERS}" -a -z "$(echo $@ | grep -- --bootstrap-server)" ]; then
    BOOTSTRAP_SERVER_OPT="--bootstrap-server ${KAFKA_BOOTSTRAP_SERVERS}"
fi

# Set ZOOKEEPER_CONNECT_OPT if KAFKA_ZOOKEEPER_URL is set and '--authorizer-properties zookeeper.connect'
# has not also been passed in as a CLI arg.  This will be included
# in command functions that take '--authorizer-properties zookeeper.connect' argument.
if [ -n "${KAFKA_ZOOKEEPER_URL}" -a -z "$(echo $@ | egrep -- '--authorizer-properties\ *zookeeper\.connect')" ]; then
    ZOOKEEPER_CONNECT_OPT="--authorizer-properties zookeeper.connect=${KAFKA_ZOOKEEPER_URL}"
fi

# Each of these lists signifies that either --broker-list, --bootstrap-server,
# or --zookeeper needs to be given to the $command.  If $command matches one of these,
# then we will add the opt if it is not provided already in $@.
# Until https://issues.apache.org/jira/browse/KAFKA-4307 is available, there are
# inconsistencies in broker CLI parameters.  Some use --bootstrap-server, others
# use --broker-list, so we have to support both for now.
# --broker-list should be removed in later versions in favor of --bootstrap-server
broker_list_commands="kafka-console-producer "\
"kafka-consumer-perf-test "\
"kafka-replay-log-producer "\
"kafka-replica-verification "\
"kafka-simple-consumer-shell "\
"kafka-verifiable-consumer "\
"kafka-verifiable-producer"

bootstrap_server_commands="kafka-console-consumer "\
"kafka-broker-api-versions "\
"kafka-consumer-groups "

zookeeper_commands="kafka-configs "\
"kafka-consumer-offset-checker.sh "\
"kafka-preferred-replica-election "\
"kafka-reassign-partitions "\
"kafka-replay-log-producer "\
"kafka-topics"

zookeeper_connect_commands="kafka-acls"

EXTRA_OPTS=""
echo "${broker_list_commands}" | /bin/grep -q "${command}" && EXTRA_OPTS="${BROKER_LIST_OPT} "
echo "${bootstrap_server_commands}" | /bin/grep -q "${command}" && EXTRA_OPTS="${EXTRA_OPTS}${BOOTSTRAP_SERVER_OPT} "
echo "${zookeeper_commands}" | /bin/grep -q "${command}" && EXTRA_OPTS="${EXTRA_OPTS}${ZOOKEEPER_OPT} "
echo "${zookeeper_connect_commands}" | /bin/grep -q "${command}" && EXTRA_OPTS="${EXTRA_OPTS}${ZOOKEEPER_CONNECT_OPT} "

# Print out the command we are about to exec, and then run it
# set -f to not expand wildcards in command, e.g. --topic '*'
set -f
echo ${command} ${EXTRA_OPTS}"$@"
${command} ${EXTRA_OPTS}"$@"
