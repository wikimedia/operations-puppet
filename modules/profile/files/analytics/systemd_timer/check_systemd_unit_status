#!/bin/bash

# Usage:
#    check_systemd_unit_status systemd_unit_name
#
# The script checks the current status of the given systemd unit name,
# alerting if it is 'failed'.
#


if [ -z "$1" ]
then
    echo "usage: check_systemd_unit_status systemd_unit_name"
    exit 3
fi

if /bin/systemctl --quiet is-failed $1
then
    echo "CRITICAL: Status of the systemd unit $1"
    exit 2
else
    echo "OK: Status of the systemd unit $1"
    exit 0
fi