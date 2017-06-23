#!/bin/bash
# Nagios/Icinga plugin to check for oversized exim4 queues.
#
# Daniel Zahn - Wikimedia Foundation Inc.
#
# https://phabricator.wikimedia.org/T133110
#
# ./check_exim_queue -w <warn> -c <crit>
#
# <warn> = number of mails in queue that trigger a WARN (int)
# <crit> = number of mails in queue that trigger a CRIT (int)
#
# dependencies: exipick, sudo

set -eu

usage() { echo "Usage: $0 -w <warn> -c <crit>" 1>&2; exit 1; }

declare -i WARN_LIMIT=0
declare -i CRIT_LIMIT=0

# count only messages older than MIN_AGE
MIN_AGE="10m"

while getopts "w:c:" o; do
    case "${o}" in
    w)
       WARN_LIMIT=${OPTARG}
       ;;
    c)
       CRIT_LIMIT=${OPTARG}
       ;;
    *)
       usage
       ;;
    esac
done

if [ $WARN_LIMIT == 0 ] || [ $CRIT_LIMIT == 0 ]; then
    usage
fi

declare -i QSIZE=0

SUDO="/usr/bin/sudo"
EXIPICK="/usr/sbin/exipick"

# number of messages in queue older than $MIN_AGE
QSIZE="$(${SUDO} ${EXIPICK} -bpc -o ${MIN_AGE})"

# echo "QSIZE: ${QSIZE} WARN: ${WARN_LIMIT} CRIT: ${CRIT_LIMIT}"

if [ "$QSIZE" -ge "$CRIT_LIMIT" ] ; then
    echo "CRITICAL: ${QSIZE} mails in exim queue."
    exit 2
fi

if [ "$QSIZE" -ge "$WARN_LIMIT" ] ; then
    echo "WARNING: ${QSIZE} mails in exim queue."
    exit 1
fi

if [ "$QSIZE" -lt "$WARN_LIMIT" ] && [ "$QSIZE" -lt "$CRIT_LIMIT" ] ; then
    echo "OK: Less than ${WARN_LIMIT} mails in exim queue."
    exit 0
fi

echo "UNKNOWN: something went wrong. check plugin ($0)."
exit 3

