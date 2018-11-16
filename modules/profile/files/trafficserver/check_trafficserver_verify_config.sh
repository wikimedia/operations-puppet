#!/bin/sh
#
# Copyright 2018 Emanuele Rocca
# Copyright 2018 Wikimedia Foundation, Inc.
#
# This nagios plugin is free software, and comes with ABSOLUTELY NO WARRANTY.
# It may be used, redistributed and/or modified under the terms of the GNU
# General Public Licence (see http://www.fsf.org/licensing/licenses/gpl.txt).
#

res="$(/usr/bin/traffic_server -C verify_config 2>&1 | grep 'ERROR')"

if [ -z "$res" ]; then
    echo "OK: configuration valid"
    exit 0
else
    echo "WARNING: $res"
    exit 1
fi
