#!/bin/sh
#
# Copyright 2018 Emanuele Rocca
# Copyright 2018 Wikimedia Foundation, Inc.
#
# This nagios plugin is free software, and comes with ABSOLUTELY NO WARRANTY.
# It may be used, redistributed and/or modified under the terms of the GNU
# General Public Licence (see http://www.fsf.org/licensing/licenses/gpl.txt).
#

if [ ! -r /etc/trafficserver/records.config ]; then
    echo "UNKNOWN: user $(whoami) cannot read records.config"
    exit 3
fi

# Sample output:
#  $ sudo traffic_ctl config status
#  Apache Traffic Server - traffic_server - 8.0.0 - (build # 102313 on Oct 23 2018 at 13:15:58)
#  Started at Tue Oct 30 16:13:34 2018
#  Last reconfiguration at Mon Nov  5 15:37:14 2018
#  Configuration is current
res="$(/usr/bin/traffic_ctl config status | grep -E 'requires restarting|Reconfiguration required')"

if [ -z "$res" ]; then
    echo "OK: configuration is current"
    exit 0
else
    echo "WARNING: $res"
    exit 1
fi
