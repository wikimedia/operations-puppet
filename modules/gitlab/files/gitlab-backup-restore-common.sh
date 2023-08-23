#!/bin/bash
# SPDX-License-Identifier: Apache-2.0

LOCKFILE="/var/lock/gitlab-backup.lock"
TIMEOUT_DURATION=10800 # 60 * 60 * 3 = 3 hours

abort_if_locked() {
    # We chose a time-based lock here because we won't always have a PID when
    # locked. Potential cases for this are when we want to lock from a cookbook
    # being run against another host. The lock time is set fairly high, but we
    # run backups regularly enough so it's ok to skip them.
    if [ -f $LOCKFILE ]; then
        current_date="$(date +%s)"
        timeout_date="$(cat ${LOCKFILE})"

        if [ "${current_date}" -lt "${timeout_date}" ]; then
            echo "A backup or restore process is already running, or has not timed out. (Current: ${current_date}, Timeout: ${timeout_date})"
            exit 1
        fi
    fi
}

lock_backups() {
    abort_if_locked

    trap unlock SIGINT SIGHUP SIGABRT EXIT

    echo -n "Creating lockfile... "
    timeout=$(expr $(date +%s) + ${TIMEOUT_DURATION})
    echo "${timeout}" > $LOCKFILE

    echo "Done"
}

unlock() {
    echo -n "Cleaning up -- removing ${LOCKFILE}... "
    rm -f ${LOCKFILE}
    echo "Done"
}
