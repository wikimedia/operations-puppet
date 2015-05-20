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

handlers = {}


def dispatch_stat(*args):
    args = list(args)
    value = args.pop()
    name = '.'.join(args)
    stat = '%s:%s|ms' % (name, value)
    sock.sendto(stat.encode('utf-8'), addr)


def handles(schema):
    def wrapper(f):
        handlers[schema] = f
        return f
    return wrapper


def is_sane(value):
    return isinstance(value, int) and value > 0 and value < 60000


@handles('SaveTiming')
def handle_save_timing(meta):
    event = meta['event']
    duration = event.get('saveTiming')
    if duration is None:
        duration = event.get('duration')
    if is_sane(duration):
        dispatch_stat('mw.performance.save', duration)


@handles('NavigationTiming')
def handle_navigation_timing(meta):
    event = meta['event']
    metrics = {}

    for metric, marker in (
        ('dnsLookup', 'dnsLookup'),
        ('loading', 'loadEventStart'),
        ('mediaWikiLoadComplete', 'mediaWikiLoadComplete'),
        ('redirecting', 'redirecting'),
        ('sending', 'fetchStart'),
        ('totalPageLoadTime', 'loadEventEnd')
    ):
        if marker in event:
            metrics[metric] = event[marker]

    for difference, minuend, subtrahend in (
        ('waiting', 'responseStart', 'requestStart'),
        ('connecting', 'connectEnd', 'connectStart'),
        ('receiving', 'responseEnd', 'responseStart'),
        ('rendering', 'loadEnd', 'responseEnd'),
        ('pageSpeed', 'loadEnd', 'domInteractive'),
        ('sslNegotiation', 'connectEnd', 'secureConnectionStart'),
    ):
        if minuend in event and subtrahend in event:
            metrics[difference] = event[minuend] - event[subtrahend]

    site = 'mobile' if 'mobileMode' in event else 'desktop'
    auth = 'anonymous' if event.get('isAnon') else 'authenticated'
    https = 'https' if event.get('isHttps') else 'http'

    # Current unused:
    bits_cache = meta.get('recvFrom', '').split('.')[0]
    wiki = meta.get('wiki', '')

    metrics = {k: v for k, v in metrics.items() if is_sane(v)}
    prefix = 'frontend.navtiming'

    if 'sslNegotiation' in metrics:
        metrics = {'sslNegotiation': metrics['sslNegotiation']}

    for metric, value in metrics.items():
        dispatch_stat(prefix, metric, site, auth, value)
        dispatch_stat(prefix, metric, site, 'overall', value)
        dispatch_stat(prefix, metric, 'overall', value)

        if metric == 'connecting':
            dispatch_stat(prefix, metric, site, https, value)


for meta in iter(zsock.recv_json, ''):
    f = handlers.get(meta['schema'])
    if f is not None:
        f(meta)
