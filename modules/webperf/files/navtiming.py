#!/usr/bin/env python
# -*- coding: utf-8 -*-
from __future__ import unicode_literals
import sys
reload(sys)
sys.setdefaultencoding("utf-8")

import argparse
import logging
import re
import socket
import unittest

import zmq
import yaml


handlers = {}


def parse_ua(ua):
    """Return the metric pair of "<browser_family>.<browser_major>" or None.

    Inspired by https://github.com/ua-parser/uap-core

    - Add unit test with sample user agent string for each match.
    - Must return a string in form "<browser_family>.<browser_major>".
    - Use the same family name as ua-parser.
    - Ensure version number match doesn't contain dots (or transform them).
    """

    # Chrome for iOS
    m = re.search('CriOS/(\d+)', ua)
    if m is not None:
        return 'Chrome_Mobile_iOS.%s' % m.group(1)

    # Mobile Safari on iOS
    m = re.search('OS [\d_]+ like Mac OS X.*Version/([\d.]+).+Safari', ua)
    if m is not None:
        return 'Mobile_Safari.%s' % '_'.join(m.group(1).split('.')[:2])

    # iOS WebView
    m = re.search('OS ([\d_]+) like Mac OS X.*Mobile', ua)
    if m is not None:
        return 'iOS_WebView.%s' % '_'.join(m.group(1).split('_')[:2])

    # Opera 14 for Android (WebKit-based)
    m = re.search('Mobile.*OPR/(\d+)', ua)
    if m is not None:
        return 'Opera_Mobile.%s' % m.group(1)

    # Android browser (pre Android 4.4)
    m = re.search('Android (\d).*Version/[\d.]+', ua)
    if m is not None:
        return 'Android.%s' % m.group(1)

    # Chrome for Android
    m = re.search('Android.*Chrome/(\d+)', ua)
    if m is not None:
        return 'Chrome_Mobile.%s' % m.group(1)

    # Opera >= 15 (Desktop)
    m = re.search('Chrome.*OPR/(\d+)', ua)
    if m is not None:
        return 'Opera.%s' % m.group(1)

    # Internet Explorer 11
    m = re.search('Trident.*rv:11\.', ua)
    if m is not None:
        return 'MSIE.11'

    # Internet Explorer <= 10
    m = re.search('MSIE (\d+)', ua)
    if m is not None:
        return 'MSIE.%s' % m.group(1)

    # Firefox for Android
    m = re.search('(?:Mobile|Tablet);.*Firefox/(\d+)', ua)
    if m is not None:
        return 'Firefox_Mobile.%s' % m.group(1)

    # Firefox (Desktop)
    m = re.search('Firefox/(\d+)', ua)
    if m is not None:
        return 'Firefox.%s' % m.group(1)

    # Microsoft Edge
    m = re.search('Edge/(\d+)\.', ua)
    if m is not None:
        return 'Edge.%s' % m.group(1)

    # Chrome/Chromium
    m = re.search('(Chromium|Chrome)/(\d+)\.', ua)
    if m is not None:
        return '%s.%s' % (m.group(1), m.group(2))

    # Safari (Desktop)
    m = re.search('Version/(\d+).+Safari/', ua)
    if m is not None:
        return 'Safari.%s' % m.group(1)

    # Misc iOS
    m = re.search('OS ([\d_]+) like Mac OS X', ua)
    if m is not None:
        return 'iOS_other.%s' % '_'.join(m.group(1).split('_')[:2])

    # Opera <= 12 (Desktop)
    m = re.match('Opera/9.+Version/(\d+)', ua)
    if m is not None:
        return 'Opera.%s' % m.group(1)

    # Opera < 10 (Desktop)
    m = re.match('Opera/(\d+)', ua)
    if m is not None:
        return 'Opera.%s' % m.group(1)


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


def is_sane_experimental(value):
    return isinstance(value, int) and value > 0 and value < 180000


@handles('SaveTiming')
def handle_save_timing(meta):
    event = meta['event']
    duration = event.get('saveTiming')
    if duration is None:
        duration = event.get('duration')
    if duration and is_sane(duration):
        dispatch_stat('mw.performance.save', duration)

        # Ori, for T126700 -- 17-Feb-2016
        if meta.get('wiki', '') == 'mediawikiwiki':
            dispatch_stat('tmp.performance.save', duration)


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

    if 'mobileMode' in event:
        if event['mobileMode'] == 'stable':
            site = 'mobile'
        else:
            site = 'mobile-beta'
    else:
        site = 'desktop'
    auth = 'anonymous' if event.get('isAnon') else 'authenticated'

    # Currently unused:
    # bits_cache = meta.get('recvFrom', '').split('.')[0]
    # wiki = meta.get('wiki', '')

    if 'sslNegotiation' in metrics:
        metrics = {'sslNegotiation': metrics['sslNegotiation']}

    for metric, value in metrics.items():
        prefix = 'frontend.navtiming'
        prefix_experimental = 'frontend.navtiming-experimental'

        if is_sane(value):
            dispatch_stat(prefix, metric, site, auth, value)
            dispatch_stat(prefix, metric, site, 'overall', value)
            dispatch_stat(prefix, metric, 'overall', value)

            ua = parse_ua(meta['userAgent']) or 'Other._'
            dispatch_stat(prefix, metric, site, 'by_browser', ua, value)

if __name__ == '__main__':
    ap = argparse.ArgumentParser(description='NavigationTiming subscriber')
    ap.add_argument('endpoint', help='URI of EventLogging endpoint')
    ap.add_argument('--statsd-host', default='localhost',
                    type=socket.gethostbyname)
    ap.add_argument('--statsd-port', default=8125, type=int)

    args = ap.parse_args()

    logging.basicConfig(format='%(asctime)-15s %(message)s',
                        level=logging.INFO, stream=sys.stdout)

    ctx = zmq.Context()
    zsock = ctx.socket(zmq.SUB)
    zsock.hwm = 3000
    zsock.linger = 0
    zsock.connect(args.endpoint)
    zsock.subscribe = b''

    addr = args.statsd_host, args.statsd_port
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)

    for meta in iter(zsock.recv_json, ''):
        f = handlers.get(meta['schema'])
        if f is not None:
            f(meta)

        if is_sane_experimental(value):
            dispatch_stat(prefix_experimental, metric, 'overall', value)


# ##### Tests ######
# To run:
#   python -m unittest navtiming
#
class TestParseUa(unittest.TestCase):

    def test_parse_ua(self):
        with open('navtiming_ua_data.yaml') as f:
            data = yaml.safe_load(f)
            for case in data:
                self.assertEqual(
                    parse_ua(case['ua']),
                    case['result']
                )
