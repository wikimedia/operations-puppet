#!/bin/bash

SCRIPT_NAME=$(basename "$0")

commands=$(ls /usr/bin/kafka-* | xargs -n 1 basename | sed 's@kafka-@  @g')

USAGE="
$SCRIPT_NAME <command> [options]

Handy wrapper around various kafka-* scripts.  Set the environment variables
ZOOKEEPER_URL and BROKER_LIST so you don't have to keep typing
--zookeeper-connect or --broker-list each time you want to use a kafka-*
script.

Usage:

Run $SCRIPT_NAME <command> with zero arguments/options to see command usage.

Commands:
$commands

Environment Variables:
  ZOOKEEPER_URL - If this is set, any commands that take a --zookeeper flag will be given this value.
  BROKER_LIST   - If this is set, any commands that take a --broker-list flag will be given this value.
"

if [ -z "${1}" -o ${1:0:1} == '-' ]; then
    echo "${USAGE}"
    exit 1
fi

# All kafka scripts start with kafka-.
command="kafka-${1}"
shift

# Set ZOOKEEPER_OPT if ZOOKEEPER_URL is set and --zookeeper has not
# also been passed in as a CLI arg.  This will be included
# in command functions that take a --zookeeper argument.
if [ -n "${ZOOKEEPER_URL}" -a -z "$(echo $@ | grep -- --zookeeper)" ]; then
    ZOOKEEPER_OPT="--zookeeper ${ZOOKEEPER_URL}"
fi

# Set BROKER_LIST_OPT if BROKER_LIST is set and --broker-list has not
# also been passed in as a CLI arg.  This will be included
# in command functions that take a --broker-list argument.
if [ -n "${BROKER_LIST}" -a -z "$(echo $@ | grep -- --broker-list)" ]; then
    BROKER_LIST_OPT="--broker-list ${BROKER_LIST}"
fi

# Each of these lists signifies that either --broker-list or --zookeeper needs
# to be given to the $command.  If $command matches one of these, then we
# will add the opt if it is not provided already in $@.
broker_list_commands="kafka-console-producer "\
"kafka-consumer-perf-test "\
"kafka-replica-verification "\
"kafka-simple-consumer-shell "\
"kafka-verifiable-consumer "\
"kafka-verifiable-producer"

zookeeper_commands="kafka-configs "\
"kafka-console-consumer "\
"kafka-consumer-groups "\
"kafka-consumer-perf-test "\
"kafka-preferred-replica-election "\
"kafka-reassign-partitions "\
"kafka-replay-log-producer "\
"kafka-topics"

EXTRA_OPTS=""
echo "${broker_list_commands}" | /bin/grep -q "${command}" && EXTRA_OPTS="${BROKER_LIST_OPT} "
echo "${zookeeper_commands}" | /bin/grep -q "${command}" && EXTRA_OPTS="${EXTRA_OPTS}${ZOOKEEPER_OPT} "

# Print out the command we are about to exec, and then run it
echo "${command} ${EXTRA_OPTS}$@"
${command} ${EXTRA_OPTS}$@
