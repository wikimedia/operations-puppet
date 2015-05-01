#!/bin/bash

# NOTE: This file is managed by Puppet.

usage="Usage:

$0 [-H <statsd_host>] [-p <statsd_port>] [-n] <metric_name>
Reads interger counts line by line from stdin and sends them as metric_name to statsd over UDP.

Options:

  -H <statsd_host> host of statsd instance.     Default: stats.eqiad.wmnet
  -p <statsd_port> UDPport of statsd instance.  Default: 8125
  -n               Dry run; statsd strings will be printed to stdout instead of sent to statsd.
  -h               Show this help message.
"

dry_run="false"
statsd_host="statsd.eqiad.wmnet"
statsd_port="8125"

if [ $# -eq 0 ]; then
    echo >&2 "Must specify <metric_name>"
    echo ""
    echo >&2 "${usage}"
    exit 1
fi

# parse command line arguments
# while getopts "H:p:nh" opt; do
while [[ $# > 1 ]]; do
    opt=$1

    case $opt in
        -h)
            echo "${usage}"
            exit 0
            ;;
        -n)
            dry_run="true"
            ;;
        -H)
            statsd_host=$2
            shift
            ;;
        -p)
            statsd_port=$2
            shift
            ;;
        *)
            echo >&2  "Invalid argument: ${opt}"
            echo >&2 "${usage}"
            exit 1
            ;;
    esac

    shift
done

metric_name=$1

if [ -z "${metric_name}" ]; then
    echo >&2 "Must specify <metric_name>"
    echo ""
    echo >&2 "${usage}"
    exit 1
fi


if [ "x${dry_run}" == "xtrue" ]; then
    out_to="cat"
else
    out_to="netcat -w 1 -u ${statsd_host} ${statsd_port}"
fi

while read metric_value; do
    statsd_string="$metric_name:$metric_value|c"
    echo $statsd_string
done | $out_to
