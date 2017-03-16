#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
  check_grafana_alert
  ~~~~~~~~~~~~~~~~~~~~~~~~

  Checks a Grafana dashboard and generates CRITICAL states if
  it has Grafana alerts in "alerting" state.

  Usage:
    check_grafana_alert DASHBOARD_URI GRAFANA_URL

  Positional arguments:
    DASHBOARD_URI         Grafana dashboard URI
    GRAFANA_URL           URL of grafana

"""
from __future__ import print_function

import sys
reload(sys)
sys.setdefaultencoding("utf-8")

import argparse
import json
import urllib2


ap = argparse.ArgumentParser(description='Grafana dashboard alert')
ap.add_argument('dashboard', help='dashboard URI')
ap.add_argument('grafana_url', help="URL of grafana")
args = ap.parse_args()

alerting_names = []

try:
    url = args.grafana_url + '/api/alerts'
    data = json.load(urllib2.urlopen(url))

    for record in data:
        if 'dashboardUri' in record and record['dashboardUri'] == args.dashboard:
            if 'state' in record and record['state'] == 'alerting' and 'name' in record:
                alerting_names.append(record['name'])
except Exception as e:
    print('UNKNOWN: failed to check %s/dashboard/%s due to exception: %s' % (
        args.grafana_url, args.dashboard, e.msg))
    sys.exit(3)

if len(alerting_names) > 0:
    print('CRITICAL: %s/dashboard/%s is alerting: %s.' % (
        args.grafana_url, args.dashboard, ', '.join(alerting_names)), file=sys.stderr)
    sys.exit(2)
else:
    print('OK: %s/dashboard/%s is not alerting.' % (
        args.grafana_url, args.dashboard), file=sys.stderr)
    sys.exit(0)
