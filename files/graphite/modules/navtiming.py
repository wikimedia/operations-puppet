#!/usr/bin/env python
# -*- coding: utf-8 -*-
from __future__ import unicode_literals
import sys
reload(sys)
sys.setdefaultencoding("utf-8")

import argparse
import socket

import zmq


schema_revs = (5336845, 5832704)
metrics = ('connecting', 'sending', 'waiting', 'redirecting', 'receiving',
           'rendering', 'loading', 'dnsLookup', 'pageSpeed')


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

for meta in iter(zsock.recv_json, ''):

    if meta['revision'] not in schema_revs:
        continue

    event = meta['event']

    if meta['revision'] == 5832704:
        if 'fetchStart' in event:
            event['sending'] = event['fetchStart']
        if 'loadEventStart' in event:
            event['loading'] = event['loadEventStart']
        if 'responseStart' in event and 'requestStart' in event:
            event['waiting'] = event['responseStart'] - event['requestStart']
        if 'connectEnd' in event and 'connectStart' in event:
            event['connecting'] = event['connectEnd'] - event['connectStart']
        if 'responseEnd' in event and 'responseStart' in event:
            event['receiving'] = event['responseEnd'] - event['responseStart']
        if 'loadEventEnd' in event and 'domInteractive' in event:
            event['pageSpeed'] = (
                event['loadEventEnd'] - event['domInteractive'])

    wiki = meta['wiki']
    if not event.get('isAnon'):
        continue

    site = 'mobile' if 'mobileMode' in event else 'desktop'

    for metric in metrics:
        value = event.get(metric, 0)
        if value > 0 and value < 60000:
            stat = 'browser.%s.%s:%s|ms' % (metric, site, value)
            sock.sendto(stat.encode('utf-8'), addr)
            stat = 'browser.%s.%s.%s:%s|ms' % (metric, wiki, site, value)
            sock.sendto(stat.encode('utf-8'), addr)
