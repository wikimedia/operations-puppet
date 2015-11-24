#!/usr/bin/env python
# -*- coding: utf-8 -*-
from __future__ import unicode_literals
import sys

import argparse
import socket
import re

import zmq

reload(sys)
sys.setdefaultencoding("utf-8")

ap = argparse.ArgumentParser(description='StatsD module for mw-js-deprecate')
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
    if meta['schema'] == 'DeprecatedUsage':
        key = re.sub(r'\W+', '_', meta['event']['method'])
        stat = 'mw.js.deprecate.%s:1|c' % key
        sock.sendto(stat.encode('utf-8'), addr)
