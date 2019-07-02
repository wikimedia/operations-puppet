#!/bin/bash

# Attempts to consume from the given EventStreams endpoint and looks
# for the presence of a line that begins with 'data:'.  This indicates
# a message.  Use this script to monitor an active EventStreams endpoint
# to alert if messages stop flowing through.
#
# Usage:
# ./check_eventstreams [<eventstreams-url>] [<timeout-seconds>]
#
# Default eventstreams-url is http://localhost:8092/v2/stream/recentchange
# Default timeout-seconds is 10
#

url=${1:-http://localhost:8092/v2/stream/recentchange}
timeout=${2:-10}

curl -s --max-time $timeout --header "X-Client-IP: $(hostname -i)" $url | head -n 5 | grep -qE '^data:'
exitval=$?

if [ $exitval -ne 0 ]; then
    echo "CRITICAL: No EventStreams message was consumed from $url within $timeout seconds."
    exit 2
else
    echo "OK: An EventStreams message was consumed from $url within $timeout seconds."
    exit 0
fi
