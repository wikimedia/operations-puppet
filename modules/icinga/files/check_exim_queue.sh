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
# dependencies: exipick, sudo, wc

usage() { echo "Usage: $0 -w <warn> -c <crit>" 1>&2; exit 1; }

declare -i WARN_LIMIT
declare -i CRIT_LIMIT

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

if [ -z "${WARN_LIMIT}" ] || [ -z "${CRIT_LIMIT}" ]; then
    usage
fi

declare -i QSIZE

SUDO="/usr/bin/sudo"
EXIPICK="/usr/sbin/exipick"
WC="/usr/bin/wc"

QSIZE="$(${SUDO} ${EXIPICK} -i | ${WC} -l)"

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

