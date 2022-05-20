#!/bin/bash
# SPDX-License-Identifier: Apache-2.0

set -e
set -u
source /etc/generate-thumbor-age-metrics

/bin/systemctl show -p Id -p ExecMainStartTimestampMonotonic thumbor@* | \
    /usr/bin/awk -v RS="" -v OFS="=" -v HOSTNAME=$(/bin/hostname) '{
        split($1, tstamp, "=")
        split($2, id, "@")
        print "thumbor." HOSTNAME \
          ".process." id[2] \
          ".start_timestamp_monotonic:" tstamp[2] "|g"
    }' | \
/bin/nc -w 1 -u $STATSD_HOST $STATSD_PORT
