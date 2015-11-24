#!/usr/bin/env python
# -*- coding: utf-8 -*-
from __future__ import unicode_literals
import sys

import argparse
import logging
import re
import socket

import zmq

reload(sys)
sys.setdefaultencoding("utf-8")

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


def parse_ua(ua):
    m = re.search('CriOS/(\d+)', ua)
    if m is not None:
        return 'CriOS_%s' % m.group(1)

    m = re.search('OS ([\d_]+) like Mac OS X.*Version', ua)
    if m is not None:
        return 'iOS_%s_WebView' % '_'.join(m.group(1).split('_')[:2])

    m = re.search('Mobile.*OPR/(\d+)', ua)
    if m is not None:
        return 'Mobile_Opera_%s' % m.group(1)

    m = re.search('Android (\d).*Version/[\d.]+', ua)
    if m is not None:
        return 'Android_%s_WebView' % m.group(1)

    m = re.search('Android.*Chrome/(\d+)', ua)
    if m is not None:
        return 'Mobile_Chrome_%s' % m.group(1)

    m = re.search('OPR/(\d+)', ua)
    if m is not None:
        return 'Opera_%s' % m.group(1)

    m = re.search('rv:11.0', ua)
    if m is not None:
        return 'MSIE_11'

    m = re.search('MSIE_\d+', ua)
    if m is not None:
        return m.group(0)

    m = re.search('Firefox/\d+', ua)
    if m is not None:
        return m.group(0).replace('/', '_')

    m = re.search('Chrome/(\d+)[\d.]* Safari', ua)
    if m is not None:
        return 'Chrome_%s' % m.group(1)

    m = re.search('Safari/(\d)[\d.]*$', ua)
    if m is not None:
        return 'Safari_%s' % m.group(1)

    m = re.search('Edge/(\d+)[\d.]*$', ua)
    if m is not None:
        return 'Edge_%s' % m.group(1)

    m = re.search('OS ([\d_]+) like Mac OS X', ua)
    if m is not None:
        return 'iOS_%s_other' % '.'.join(m.group(1).split('_')[:2])

    m = re.match('Opera/(\d+)', ua)
    if m is not None:
        return 'Opera_%s' % m.group(1)


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
    if duration and is_sane(duration):
        dispatch_stat('mw.performance.save', duration)


@handles('NavigationTiming')
def handle_navigation_timing(meta):
    event = meta['event']
    metrics = {}

    for metric, marker in (
        ('dnsLookup', 'dnsLookup'),
        ('loading', 'loadEventStart'),
        ('mediaWikiLoadStart', 'mediaWikiLoadStart'),
        ('mediaWikiLoadEnd', 'mediaWikiLoadEnd'),
        ('mediaWikiLoadComplete', 'mediaWikiLoadComplete'),
        ('redirecting', 'redirecting'),
        ('sending', 'fetchStart'),
        ('totalPageLoadTime', 'loadEventEnd'),
        ('responseStart', 'responseStart'),
        ('firstPaint', 'firstPaint'),
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

    # Currently unused:
    # bits_cache = meta.get('recvFrom', '').split('.')[0]
    # wiki = meta.get('wiki', '')

    if 'sslNegotiation' in metrics:
        metrics = {'sslNegotiation': metrics['sslNegotiation']}

    for metric, value in metrics.items():
        prefix = 'frontend.navtiming'

        if is_sane(value):
            dispatch_stat(prefix, metric, site, auth, value)
            dispatch_stat(prefix, metric, site, 'overall', value)
            dispatch_stat(prefix, metric, 'overall', value)

            prefix = prefix + '.by_platform'
            ua = parse_ua(meta['userAgent'])
            if ua:
                dispatch_stat(prefix, ua, metric, site, value)


for meta in iter(zsock.recv_json, ''):
    f = handlers.get(meta['schema'])
    if f is not None:
        f(meta)
