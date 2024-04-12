#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
#
# rsyslogs imfile plugin does not properly close inotify watches when container
# logs/their symlinks have been removed. Over time this leads to rsyslog reaching the
# maximum number of open files allowed.
# https://phabricator.wikimedia.org/T357616
#
# This script will check if the number of inotify watches for deleted files/direcotries
# is above 10000 (which is a value I randomly choose) and restart rsyslog if so.
# A different threshold can be passed as an argument to the script.

threshold=${1:-10000}
rsyslog_pid="$(systemctl show --property MainPID --value rsyslog.service)"
deleted_file_fds="$(lsof -p "${rsyslog_pid}" | grep -c '(deleted)')"

if [ "$deleted_file_fds" -gt "$threshold" ]; then
    echo "Number of inotify watches for deleted files/directories is above ${threshold}. Restarting rsyslog."
    /bin/systemctl restart rsyslog.service
fi