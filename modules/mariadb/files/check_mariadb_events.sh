#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
# NRPE check: verify all MariaDB events in the ops database are ENABLED.
# Returns CRITICAL if any event has a status other than ENABLED,
# WARNING if no events are found, OK otherwise.

set -u

if [ $# -ne 1 ]; then
    echo "UNKNOWN - Usage: $0 <socket_path>"
    exit 3
fi

SOCKET="$1"

# Query events from the ops database
output=$(mysql -S "${SOCKET}" -N -B -e "SELECT EVENT_NAME, STATUS FROM information_schema.EVENTS WHERE EVENT_SCHEMA = 'ops'" 2>&1)
rc=$?

if [ ${rc} -ne 0 ]; then
    echo "CRITICAL - Failed to query events: ${output}"
    exit 2
fi

if [ -z "${output}" ]; then
    echo "WARNING - No events found in ops database"
    exit 1
fi

disabled_events=""
total=0
while IFS=$'\t' read -r name status; do
    total=$((total + 1))
    if [ "${status}" != "ENABLED" ]; then
        if [ -n "${disabled_events}" ]; then
            disabled_events="${disabled_events}, "
        fi
        disabled_events="${disabled_events}${name}(${status})"
    fi
done <<< "${output}"

if [ -n "${disabled_events}" ]; then
    echo "CRITICAL - Events not ENABLED: ${disabled_events}"
    exit 2
fi

echo "OK - All ${total} events in ops database are ENABLED"
exit 0
