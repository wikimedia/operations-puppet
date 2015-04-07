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

    rrd-navtiming.py [-h] [--endpoint _ENDPOINT]
                          [--rrd-path RRD_PATH]

      --endpoint ENDPOINT   EventLogging endpoint URI
                            (default: tcp://eventlogging.eqiad.wmnet:8600)

      --rrd-path RRD_PATH   Path to use for RRD storage
                            (default: CWD)

  Example:

    rrd-navtiming --endpoint tcp://eventlog1001.eqiad.wmnet:8600 \
                  --rrd-path /var/lib/rrd-navtiming


  Requirements:

  * eventlogging
      https://github.com/wikimedia/mediawiki-extensions-EventLogging/
      (the Python module is in server/).

  * rrdtool
      http://oss.oetiker.ch/rrdtool/prog/rrdpython.en.html


  Futher reading:

  * https://meta.wikimedia.org/wiki/Schema:NavigationTiming
  * https://www.mediawiki.org/wiki/Extension:NavigationTiming


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

import argparse
import bisect
import heapq
import logging
import os
import threading
import time

import eventlogging
import rrdtool


ap = argparse.ArgumentParser(description='Navigation Timing RRD logger')
ap.add_argument(
    '--endpoint',
    help='Endpoint URI (default: tcp://eventlogging.eqiad.wmnet:8600)',
    default='tcp://eventlogging.eqiad.wmnet:8600'
)
ap.add_argument(
    '--rrd-path',
    help='Path to use for RRD storage (default: CWD)',
    default=os.getcwd()
)
args = ap.parse_args()

logging.basicConfig(format='[%(asctime)-15s] %(message)s', level=logging.INFO)


# Lock for operations that access shared dynamic data (the `heap` list).
# We could probably get by without locks, because only the main thread
# mutates the sample heap -- the worker thread only reads it.
lock = threading.Lock()

# A min-heap of of (timestamp, event) tuples.
heap = []

# Maintain a separate RRD file with a full set of metrics for each:
PLATFORMS = ('desktop', 'mobile')

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
HEARTBEAT = 60 * 60 * 24

# The expected range for measurements is 0 - 60,000 milliseconds.
MIN, MAX = 0, 60 * 1000

# List of data source ('DS') definitions in the format expected by
# rrdcreate (<http://oss.oetiker.ch/rrdtool/doc/rrdcreate.en.html>).
SOURCES = ['DS:%s:GAUGE:%d:%d:%d' % (metric, HEARTBEAT, MIN, MAX)
           for metric in METRICS]

# List of round-robin archive ('RRA') definitions in rrdcreate format.
ARCHIVES = ['RRA:AVERAGE:0.5:%d:%d' % (interval_length / ROWS, ROWS)
            for interval_length in INTERVALS]


def update_rrds():
    """Push updates to RRD."""
    # Prune old entries.
    cutoff = time.time() - WINDOW_SIZE
    with lock:
        # Python's heapq is a min heap, meaning heap[0] is always
        # the oldest entry.
        while heap and heap[0][0] < cutoff:
            heapq.heappop(heap)

    # Don't push an update if we have fewer than 100 samples.
    # I expect this to only happy at program start.
    if len(heap) < 500:
        logging.warning('update_rrds(): fewer than 500 samples available; '
                        'aborting update.')
        return

    try:
        with lock:
            data = accumulate()
    except ValueError:
        # We don't have any data for one or more metrics.
        # We have to give RRD a full update or nothing, so move on.
        logging.warning('update_rrds(): fewer than 100 samples available; '
                        'aborting.')
        return

    for platform, samples in data.items():
        rrd_file = platform + '.rrd'
        # We have to output values in the order we declared them.
        update = 'N:' + ':'.join(str(samples[m]) for m in METRICS)
        logging.info('%s: %s', rrd_file, update)
        rrdtool.update(rrd_file, update)


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


def accumulate():
    """Group samples by metric and platform and compute medians."""
    data = {p: {m: [] for m in METRICS} for p in PLATFORMS}
    for timestamp, event in heap:
        platform = 'mobile' if 'mobileMode' in event else 'desktop'
        for metric in METRICS:
            value = event.get(metric)
            if value:
                bisect.insort(data[platform][metric], value)
    for platform in PLATFORMS:
        for metric in METRICS:
            values = data[platform][metric]
            try:
                data[platform][metric] = median(values)
            except ValueError:
                logging.warning('No values for %s on %s', metric, platform)
                raise
    return data


def create_rrds(path):
    """Create RRD files."""
    for platform in PLATFORMS:
        rrd_file = os.path.join(path, platform + '.rrd')
        args = [
            rrd_file,
            '--no-overwrite',
            '--step', str(STEP),
            '--start', 'N'
        ] + SOURCES + ARCHIVES
        try:
            rrdtool.create(*args)
        except Exception as e:
            if not e.message.endswith('File exists'):
                raise
        else:
            logging.info('Created %s', rrd_file)


create_rrds(args.rrd_path)
logging.info('Connecting to %s...', args.endpoint)
events = eventlogging.connect(args.endpoint)

worker = eventlogging.PeriodicThread(interval=STEP, target=update_rrds)
worker.daemon = True
worker.start()

for meta in events.filter(schema='NavigationTiming'):
    sample = meta['timestamp'], meta['event']
    with lock:
        heapq.heappush(heap, sample)
