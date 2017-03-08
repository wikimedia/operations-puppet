#!/bin/bash

set -e
set -u

/bin/systemctl show -p Id -p ExecMainStartTimestampMonotonic thumbor@* | \
    /usr/bin/awk -v RS="" -v OFS="=" -v HOSTNAME=$(/bin/hostname) '{
        split($1, tstamp, "=")
        split($2, id, "@")
        print "thumbor." HOSTNAME \
          ".process." id[2] \
          ".start_timestamp_monotonic." tstamp[2] "|g"
    }'
