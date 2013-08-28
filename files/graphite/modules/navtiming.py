#!/usr/bin/env python
# -*- coding: utf-8 -*-
from __future__ import unicode_literals
import sys
reload(sys)
sys.setdefaultencoding("utf-8")

import argparse
import socket

import zmq


schema_rev = 5336845
metrics = ('connecting', 'sending', 'waiting', 'redirecting', 'receiving',
           'rendering', 'loading')
countries = ('US', 'GB', 'JP', 'DE', 'RU', 'BR', 'CA', 'FR', 'IN')


ap = argparse.ArgumentParser(description='NavigationTiming Graphite module')
ap.add_argument('endpoint', help='URI of EventLogging endpoint')
ap.add_argument('--statsd-host', default='localhost',
                type=socket.gethostbyname)
ap.add_argument('--statsd-port', default=8125, type=int)

args = ap.parse_args()

ctx = zmq.Context()
zsock = ctx.socket(zmq.SUB)
zsock.hwm = 3000
zsock.linger = 0
zsock.connect(args.endpoint)
zsock.subscribe = b''

addr = args.statsd_host, args.statsd_port
sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
for meta_event in iter(zsock.recv_json, ''):
    if meta_event['revision'] != schema_rev:
        continue
    event = meta_event['event']
    if not event.get('isAnon'):
        continue
    if 'mobileMode' in event:
        site = 'mobile.' + event['mobileMode']
    else:
        site = 'desktop'
    metric_strings = [site]
    if event.get('originCountry') in countries:
        metric_strings.append('%s.%s' % (event['originCountry'], site))
    for metric in metrics:
        if event.get(metric) < 0:
            continue
        for metric_string in metric_strings:
            stat = ('navigation_timing.%s.%s:%s|ms' %
                    (metric_string, metric, event[metric]))
            print stat
    stat = stat.encode('utf-8')
    sock.sendto(stat, addr)
