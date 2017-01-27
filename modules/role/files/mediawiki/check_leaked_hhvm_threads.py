#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
#  Copyright 2016 Giuseppe Lavagetto <joe@wikimedia.org>
#
#  Permission to use, copy, modify, and/or distribute this software for any
#  purpose with or without fee is hereby granted, provided that the above
#  copyright notice and this permission notice appear in all copies.
#
#  THE SOFTWARE IS PROVIDED 'AS IS' AND THE AUTHOR DISCLAIMS ALL WARRANTIES
#  WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
#  MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
#  ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
#  WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
#  ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
#  OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
#
'''
check_leaked_hhvm_threads

usage: check_leaked_hhvm_threads

Checks that there aren't many orphaned HHVM threads that are still running detached
from the apache frontend.
'''
# This can happen because of bugs in apache, see
# e.g. https://bz.apache.org/bugzilla/show_bug.cgi?id=56188
import re
import sys

import requests

# Let's get a warning if the number of threads+queued on HHVM is 20% higher than the apache
# busy workers
PERC_WARNING = 1.2
# And alarm when the number is twice that
PERC_CRITICAL = 2.0

# Perform checks only if the uptime is more than this threshold (seconds).
UPTIME_THRESHOLD = 7200

# I know there is a race condition here. But we can live with that.
try:
    apache_status = requests.get('http://127.0.0.1/server-status?auto')
    # For some versions of httpd (like 2.4.7), BusyWorkers are set to zero when
    # a graceful restart happens, even if outstanding requests are not dropped
    # or marked as Graceful closing.
    # This means that daily tasks like logrotate cause false positives.
    # A quick workaround is to limit the check only when the Uptime is more
    # than a couple of hours, to give httpd time to restore its busy workers.
    # This is not an ideal solution but a constant rate of false positives
    # decreases the perceived importance of the alarm over time.
    uptime = re.search('Uptime: (\d+)', apache_status.text)
    if int(uptime) < UPTIME_THRESHOLD:
        print('OK')
        sys.exit(0)
    match = re.search('BusyWorkers: (\d+)', apache_status.text)
    if not match:
        print('UNKNOWN - Could not find apache busy workers in apache status')
        sys.exit(3)
    busy_workers = int(match.group(1))
except:
    print('UNKNOWN - Error fetching apache status')
    sys.exit(3)


try:
    hhvm_health = requests.get('http://127.0.0.1:9002/check-health').json()
    hhvm_reqs = int(hhvm_health['load']) + int(hhvm_health['queued'])
except:
    print('UNKNOWN - Error fetching the HHVM status')
    sys.exit(3)

if hhvm_reqs <= busy_workers * PERC_WARNING:
    print('OK')
    sys.exit(0)
elif hhvm_reqs <= busy_workers * PERC_CRITICAL:
    print('WARNING: hhvm is leaking a few threads')
    sys.exit(1)
else:
    print('CRITICAL: HHVM has more than double threads running or queued '
          'than apache has busy workers')
    sys.exit(2)
