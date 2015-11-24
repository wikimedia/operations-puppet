#!/usr/bin/env python
# -*- coding: utf-8 -*-
from __future__ import unicode_literals
import sys

import argparse
import socket

import eventlogging

reload(sys)
sys.setdefaultencoding("utf-8")

ap = argparse.ArgumentParser(description='PerfData StatsD module')
ap.add_argument('endpoint', help='URI of EventLogging endpoint')
ap.add_argument('--statsd-host', default='localhost',
                type=socket.gethostbyname)
ap.add_argument('--statsd-port', default=8125, type=int)
args = ap.parse_args()

addr = args.statsd_host, args.statsd_port
sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)

events = eventlogging.connect(args.endpoint)

for meta in events.filter(schema='Edit'):
    event = meta['event']
    if event['editor'] == 'visualeditor':
        try:
            action = event['action']
            if action == 'saveSuccess':
                metric = 'save'
            elif action == 'ready':
                metric = 'load'
            else:
                continue
            timing = int(event['action.%s.timing' % action])
            if timing < 100 or timing > 100000:
                continue
            stat = 'VisualEditor.%s:%s|ms' % (metric, timing)
            sock.sendto(stat.encode('utf-8'), addr)
        except (ValueError, KeyError):
            continue
