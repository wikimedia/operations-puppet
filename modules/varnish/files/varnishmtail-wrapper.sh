#!/bin/bash
#
# varnishmtail-wrapper - pipe varnishncsa frontend output to mtail
#
# Usage:   varnishmtail-wrapper PROG PORT INSTANCE FMT
#

# Treat unset variables as an error when substituting
set -u

PROGS=${1?missing mtail programs directory}
PORT=${2?missing mtail port number}
INSTANCE=${3?missing varnishmtail instance name}
FMT=${4?missing varnishncsa format string}

# Pass -c and -b to log requests from clients (tls terminators) and to backends (origin)
/usr/bin/varnishncsa -P "/run/${INSTANCE}.pid" -n frontend -c -b -F "${FMT}" | /usr/bin/mtail -progs "${PROGS}" -port "${PORT}" -logs /dev/stdin -disable_fsnotify &

while :; do
    sleep 1

    if ! kill -0 "$(cat /run/${INSTANCE}.pid)" 2> /dev/null ; then
        echo "varnishncsa seems to have crashed, exiting" >&2
        exit 1
    fi
done
