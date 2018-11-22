#!/bin/sh
#
# Copyright 2018 Emanuele Rocca
# Copyright 2018 Wikimedia Foundation, Inc.
#
# This nagios plugin is free software, and comes with ABSOLUTELY NO WARRANTY.
# It may be used, redistributed and/or modified under the terms of the GNU
# General Public Licence (see http://www.fsf.org/licensing/licenses/gpl.txt).
#
# Ensure that fifo-log-demux has opened the named pipe $filename for reading,
# and that TS_MAIN is writing on the other side of the pipe.
#
# Usage: check_trafficserver_log_fifo filename

filename="$1"

if [ -z "$filename" ]; then
    echo "Usage: $0 filename"
    exit 1
fi

if [ ! -e "$filename" ]; then
    echo "CRITICAL: $filename - does not exist"
    exit 2
fi

if [ ! -p "$filename" ]; then
    echo "CRITICAL: $filename - not a pipe"
    exit 2
fi

lsof -E -u trafficserver -c fifo-log-demux -a "$filename" |
    awk '
NR==2 {
   fifo_log_demux_fd = $4
   ts_main_fd = $10
}
END {
   crit = "CRITICAL: '$filename'"

   if (fifo_log_demux_fd !~ "[0-9]+r$") {
       print crit " - fifo-log-demux not reading from pipe"
       exit 2
   } else if (ts_main_fd !~ "TS_MAIN\\],[0-9]+w$") {
       print crit " - TS_MAIN not writing to pipe"
       exit 2
   } else {
       print "OK: TS_MAIN writing to and fifo-log-demux reading from '$filename'"
       exit 0
   }
}
'
