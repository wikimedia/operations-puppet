#!/bin/sh
set -eu

OK=0
WARNING=1
CRITICAL=2
UNKNOWN=3

DIRECTORY="$1"


if [ ! -d "$DIRECTORY" ]; then
    echo "UNKNOWN: $DIRECTORY does not exist"
    exit $UNKNOWN
fi

CONTENTS="$(ls $DIRECTORY)"
if [ $? -ne 0 ]; then
    echo "UNKNOWN: unable to ls $DIRECTORY"
    exit $UNKNOWN
fi

if [ -n "$CONTENTS" ]; then
    echo "CRITICAL: fastnetmon is alerting for $CONTENTS"
    exit $CRITICAL
else
    echo "OK: no fastnetmon alerts"
    exit $OK
fi
