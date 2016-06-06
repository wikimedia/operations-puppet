#!/bin/bash
set -u
# Find any stacktraces we still did not act upon
for TRACE in "/var/log/hhvm/stacktrace.*.log";
do
    if [ -e $TRACE ]; then
        # Log the stack trace
        /usr/bin/logger --tag hhvm-fatal --file ${TRACE}

        # Append the current UTC date (in YYYYMMDD format) to the file
        # name, so it doesn't get clobbered when the PID is recycled.
        mv --backup "$TRACE" "${TRACE}.$(date -u +%Y%m%d)"
    fi;
done
