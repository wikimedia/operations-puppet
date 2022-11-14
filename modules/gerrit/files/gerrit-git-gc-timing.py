#!/usr/bin/python3
# SPDX-License-Identifier: Apache-2.0
#
# Reports `git gc` duration per repositories
#
# Author: Tyler Cipriani
# Reference: https://phabricator.wikimedia.org/T237807

import datetime
import re
import time

with open('/var/log/gerrit/gc_log') as f:
    gc_log = f.readlines()

BEFORE = 'before'
AFTER = 'after'


def format_time(timestamp):
    time_obj = time.strptime(timestamp, r'%Y-%m-%d %H:%M:%S,%f')
    return time.mktime(time_obj)


logs = {}
for log in gc_log:
    log_line = re.match(
        r'^\[([\d-]{10} [\d:,]{12})\].*?: \[(.*?)\] (before|after):',
        log
    )

    if not log_line:
        continue

    timestamp = format_time(log_line.group(1))
    repo = log_line.group(2)

    if not logs.get(repo):
        logs[repo] = {}

    if log_line.group(3) == BEFORE:
        logs[repo]['start'] = timestamp
    if log_line.group(3) == AFTER:
        logs[repo]['end'] = timestamp

total_seconds = 0
for log in logs:
    elapsed = logs[log]['end'] - logs[log]['start']
    total_seconds += elapsed
    print('{}\t{}'.format(datetime.timedelta(seconds=elapsed), log))

print('{}\tTOTAL'.format(datetime.timedelta(seconds=total_seconds)))
