#!/usr/bin/env python
# -*- coding: utf-8 -*-
from __future__ import unicode_literals
import sys
reload(sys)
sys.setdefaultencoding("utf-8")

import argparse
import logging
import socket

import zmq


metrics = ('connecting', 'sending', 'waiting', 'redirecting', 'receiving',
           'rendering', 'loading', 'dnsLookup', 'pageSpeed',
           'totalPageLoadTime', 'mediaWikiLoadComplete')
prefix = 'frontend.navtiming'


ap = argparse.ArgumentParser(description='NavigationTiming Graphite module')
ap.add_argument('endpoint', help='URI of EventLogging endpoint')
ap.add_argument('--statsd-host', default='localhost',
                type=socket.gethostbyname)
ap.add_argument('--statsd-port', default=8125, type=int)

args = ap.parse_args()

logging.basicConfig(format='%(asctime)-15s %(message)s', level=logging.INFO,
                    stream=sys.stdout)

ctx = zmq.Context()
zsock = ctx.socket(zmq.SUB)
zsock.hwm = 3000
zsock.linger = 0
zsock.connect(args.endpoint)
zsock.subscribe = b''

addr = args.statsd_host, args.statsd_port
sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)


def dispatch_stat(*args):
    if len(args) < 2:
        raise argparse.ArgumentError
    args = list(args)
    value = args.pop()
    name = '.'.join([prefix] + args)
    stat = '%s:%s|ms' % (name, value)
    sock.sendto(stat.encode('utf-8'), addr)


def handle_save_timing(meta):
    event = meta['event']
    duration = event['duration']
    runtime = event['runtime']
    if duration > 0 and duration < 60000:
        stat = 'mw.performance.save.%s:%s|ms' % (runtime, duration)
        sock.sendto(stat.encode('utf-8'), addr)


def handle_navigation_timing(meta):
    event = meta['event']

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
    if 'loadEventEnd' in event and 'responseEnd' in event:
        event['rendering'] = event['loadEventEnd'] - event['responseEnd']
    if 'loadEventEnd' in event and 'domInteractive' in event:
        event['pageSpeed'] = (
            event['loadEventEnd'] - event['domInteractive'])
    if 'loadEventEnd' in event:
        event['totalPageLoadTime'] = event['loadEventEnd']

    site = 'mobile' if 'mobileMode' in event else 'desktop'
    auth = 'anonymous' if event.get('isAnon') else 'authenticated'
    runtime = event.get('runtime')

    # bits_cache = meta.get('recvFrom', '').split('.')[0]
    # wiki = meta.get('wiki', '')

    for metric in metrics:
        value = event.get(metric, 0)
        if value > 0 and value < 60000:
            dispatch_stat(metric, site, auth, value)
            dispatch_stat(metric, site, 'overall', value)
            dispatch_stat(metric, 'overall', value)

            if runtime is not None:
                # PHP5/HHVM-qualified metrics
                dispatch_stat(runtime, metric, site, auth, value)
                dispatch_stat(runtime, metric, site, 'overall', value)
                dispatch_stat(runtime, metric, 'overall', value)


for meta in iter(zsock.recv_json, ''):
    if meta['schema'] == 'NavigationTiming':
        handle_navigation_timing(meta)
    if meta['schema'] == 'SaveTiming':
        handle_save_timing(meta)
