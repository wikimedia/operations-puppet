#!/bin/bash

set -e

while read -r CONTROLLER; do
    /usr/bin/sudo /usr/sbin/hpssacli controller slot="${CONTROLLER}" ld all show detail
    echo
done < <(/usr/bin/sudo /usr/sbin/hpssacli controller all show | egrep -o 'Slot [0-9] ' | cut -d' ' -f2)
