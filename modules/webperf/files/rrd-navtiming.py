# -*- coding: utf-8 -*-
"""
  rrd-navtiming
  ~~~~~~~~~~~~~

  This script provides simple, minimal and robust storage for a small
  set of time-series metrics. The idea is not to replace a full-fledged
  time-series database but to implement the bare minimum subset of
  features required to power a site like <https://status.github.com/>.

  rrd-navtiming subscribes to NavigationTiming events via EventLogging
  and it updates a pair of RRD files in its working directory: mobile.rrd
  and desktop.rrd. If the files do not exist, they are created.

  Usage:

      rrd-navtiming EVENTLOGGING_ENDPOINT

  For example:

      rrd-navtiming tcp://eventlog1001.eqiad.wmnet:8600

  Requirements:

      * eventlogging
        https://github.com/wikimedia/mediawiki-extensions-EventLogging/
      * rrdtool
        http://oss.oetiker.ch/rrdtool/prog/rrdpython.en.html

  Copyright 2015 Ori Livneh <ori@wikimedia.org>

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

      http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

"""
import sys
reload(sys)
sys.setdefaultencoding('utf-8')

import bisect
import heapq
import logging

import eventlogging
import rrdtool

if len(sys.argv) != 2:
    sys.exit('Usage: %s EVENTLOGGING_ENDPOINT' % sys.argv[0])

logging.basicConfig(format='[%(asctime)-15s] %(message)s', level=logging.INFO)

PLATFORMS = ('mobile', 'desktop')

METRICS = (
    'responseStart',  # Time to user agent receiving first byte
    'firstPaint',     # Time to initial render
    'domComplete',    # Time to DOM Comlete event
    'loadEventEnd',   # Time to load event completion
)

# Size of sliding window, in seconds.
WINDOW_SIZE = 300

# Aggregation intervals.
INTERVALS = (
    60 * 60,                # Hour
    60 * 60 * 24,           # Day
    60 * 60 * 24 * 7,       # Week
    60 * 60 * 24 * 30,      # Month
    60 * 60 * 24 * 365.25,  # Year
)

# Store 120 values at each resolution. This makes graphing simpler,
# because we're always working with a fixed number of points.
ROWS = 120

# We will push an aggregate value as often as we need in order to have
# ROWS many values at the smallest INTERVAL.
STEP = INTERVALS[0] / ROWS

# Set the maximum acceptable interval between samples ("heartbeat") to a
# full day. This means RRD will record an estimate for missing samples as
# long as it has at least one sample from the last 24h to go by. If we go
# longer than 24h without reporting a measurement, RRD will record a value
# of UNKNOWN instead.
HEARTBEAT = 86400

# The expected range for measurements is 0 - 60,000 milliseconds.
MIN, MAX = 0, 30000

SOURCES = ['DS:%s:GAUGE:%d:%d:%d' % (metric, HEARTBEAT, MIN, MAX)
           for metric in METRICS]

ARCHIVES = ['RRA:AVERAGE:0.5:%d:%d' % (interval_length / ROWS, ROWS)
            for interval_length in INTERVALS]


def median(sorted_list):
    """Compute the median of a sorted list."""
    if not sorted_list:
        raise ValueError('Cannot compute median of empty list.')
    length = len(sorted_list)
    index = (length - 1) // 2
    if length % 2:
        return sorted_list[index]
    sum_of_terms = sorted_list[index] + sorted_list[index + 1]
    return sum_of_terms / 2.0


def accumulate(event_data):
    """Group samples by metric and platform and compute medians."""
    data = {p: {m: [] for m in METRICS} for p in PLATFORMS}
    for timestamp, event in event_data:
        platform = 'mobile' if 'mobileMode' in event else 'desktop'
        for metric in METRICS:
            value = event.get(metric)
            if value:
                bisect.insort(data[platform][metric], value)
    for platform in PLATFORMS:
        for metric in METRICS:
            values = data[platform][metric]
            data[platform][metric] = median(values)
    return data


# Create RRD files.
for platform in PLATFORMS:
    rrd_file = platform + '.rrd'
    args = [
        rrd_file,
        '--no-overwrite',
        '--step', str(STEP),
        '--start', 'N'
    ] + SOURCES + ARCHIVES
    try:
        rrdtool.create(*args)
    except rrdtool.OperationalError as e:
        if not e.message.endswith('File exists'):
            raise

# Ensure we wait and accumulate data for a full WINDOW_SIZE
# before we report any metrics.
last_update = time.time() + WINDOW_SIZE

events = eventlogging.connect(sys.argv[1])

for meta in events.filter(schema='NavigationTiming'):
    sample = meta['timestamp'], meta['event']
    heapq.heappush(heap, sample)

    now = time.time()

    # Prune old entries. Python's heapq is a min heap,
    # meaning heap[0] is always the oldest entry.
    cutoff = now - WINDOW_SIZE
    while heap[0][0] < cutoff:
        heapq.heappop(heap)

    # Check if we should push updates to RRD.
    if now - last_update >= STEP:
        last_update = now
        try:
            data = accumulate(heap)
        except ValueError:
            # We don't have any data for one or more metrics.
            # We have to give RRD a full update or nothing, so move on.
            continue

        # Actually push updates.
        for platform in PLATFORMS:
            rrd_file = platform + '.rrd'
            values = data[platform]
            update = 'N:' + ':'.join(str(values[m]) for m in METRICS)
            logging.info('%s: %s', rrd_file, update)
            rrdtool.update(rrd_file, update)
