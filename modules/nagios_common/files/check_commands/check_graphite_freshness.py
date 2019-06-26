#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
  check_graphite_freshness
  ~~~~~~~~~~~~~~~~~~~~~~~~

  Checks a Graphite metric and generates WARNING or CRITICAL states if
  the most recent datapoint is older than the required freshness threshold.

  Usage:
    check_graphite_freshness [-w THRESHOLD] [-c THRESHOLD] METRIC RENDER_URL

  Positional arguments:
    METRIC                metric name
    RENDER_URL            URL of graphite's render API

  Optional arguments:
    -w THRESHOLD, --warning THRESHOLD   warn if most recent datapoint
                                        is older than this value
    -c THRESHOLD, --critical THRESHOLD  alert if most recent datapoint
                                        is older than this value

"""
from __future__ import print_function

import sys
reload(sys)
sys.setdefaultencoding("utf-8")

import argparse
import datetime
import json
import os
import urllib2


def time_spec(spec_string):
    """Parse a time specification string consisting of a number
    followed by an optional letter specifying the unit."""
    units = {'s': 'seconds', 'm': 'minutes', 'h': 'hours', 'd': 'days'}
    if spec_string[-1].isalpha():
        unit = units[spec_string[-1]]
        count = int(spec_string[:-1])
    else:
        unit = 'seconds'
        count = int(spec_string)
    return datetime.timedelta(**{unit: count})


ap = argparse.ArgumentParser(description='Graphite staleness alert')
ap.add_argument('metric', help='metric name')
ap.add_argument('render_url', help="URL of graphite's render API")
ap.add_argument('-w', '--warning', type=time_spec, metavar='THRESHOLD',
                help='warn if most recent datapoint is older than this value')
ap.add_argument('-c', '--critical', type=time_spec, metavar='THRESHOLD',
                help='alert if most recent datapoint is older than this value')
args = ap.parse_args()
if args.critical is None and args.warning is None:
    ap.error('You must specify one (or both) of -w/--warning or -c/--critical')


try:
    req = urllib2.Request('{}?format=json&target={}'.format(
        args.render_url,
        args.metric))
    req.add_header(
        'User-Agent',
        'wmf-icinga/{} root@wikimedia.org'.format(os.path.basename(__file__)))
    data = json.load(urllib2.urlopen(req))[0]
    most_recent = datetime.datetime.utcfromtimestamp(max(
            ts for value, ts in data['datapoints'] if value is not None))
    staleness = datetime.datetime.utcnow() - most_recent
except Exception as e:
    print('UNKNOWN: failed to check %s' % args.metric)
    raise
    sys.exit(3)

if args.critical and staleness > args.critical:
    print('CRITICAL: %s is %d seconds stale.' % (
        args.metric, staleness.total_seconds()), file=sys.stderr)
    sys.exit(2)
elif args.warning and staleness > args.warning:
    print('WARNING: %s is %d seconds stale.' % (
        args.metric, staleness.total_seconds()), file=sys.stderr)
    sys.exit(1)
else:
    print('OK: %s is fresh.' % args.metric, file=sys.stderr)
    sys.exit(1)
