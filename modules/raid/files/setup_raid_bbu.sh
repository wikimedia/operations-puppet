#!/bin/bash

# This script perform 2 tasks:
# when invoked with the -c (check) flag, it checks if the RAID autolearn cycle
# is activated or not, returning 1 if it is enabled, and 0 otherwise
# when invoked without parameters, it sets the BBU properties to those on the
# /etc/BbuProperties

if [ "$1" = "-c" ]; then
    megacli -AdpBbuCmd -GetBbuProperties -a0 \
    | grep -E -q "Auto-Learn Mode: (Disabled)|(Warn via Event)"
else
    megacli -AdpBbuCmd -SetBbuProperties -f /etc/BbuProperties -a0
fi
