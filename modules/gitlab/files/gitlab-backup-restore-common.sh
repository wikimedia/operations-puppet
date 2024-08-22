#!/bin/bash
# SPDX-License-Identifier: Apache-2.0

LOCKFILE="/var/lock/gitlab-backup.lock"
TIMEOUT_DURATION=10800 # 60 * 60 * 3 = 3 hours
PROMETHEUS_PUSHGATEWAY_HOST="prometheus-pushgateway.discovery.wmnet"

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

    trap unlock_backups SIGINT SIGHUP SIGABRT EXIT

    echo -n "Creating lockfile... "
    timeout=$(expr $(date +%s) + ${TIMEOUT_DURATION})
    echo "${timeout}" > $LOCKFILE

    echo "Done"
}

unlock_backups() {
    echo -n "Cleaning up -- removing ${LOCKFILE}... "
    rm -f ${LOCKFILE}
    echo "Done"
}

send_prometheus_metrics() {
    mode=$1 # backup/restore
    type=$2 # For backup, full/partial/failover, not used for restore
    duration=$3 # Time, in seconds, that the backup lasted
    host=$HOSTNAME

    # instance= is a host with port to continue with convention, but since this is a script that runs rather
    # than a service, we use ":0" for the port.
    duration_data="gitlab_${mode}_duration_seconds{instance=\"${host}:0\", type=\"${type}\"} ${duration}"
    last_run_data="gitlab_${mode}_last_run{instance=\"${host}:0\", type=\"${type}\"} $(date +%s)"

    # We will allow this to fail, since it's only metrics. Otherwise, if this command fails because the push gateway is down or
    # not available (e.g., WMCS), the whole backup/restore will be marked as a failure.
    echo -e "${duration_data}\n${last_run_data}" | curl --data-binary @- "http://${PROMETHEUS_PUSHGATEWAY_HOST}/metrics/job/gitlab_${mode}" || true
}