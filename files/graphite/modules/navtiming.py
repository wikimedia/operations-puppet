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
           'rendering', 'loading', 'dnsLookup', 'pageSpeed',
           'totalPageLoadTime')

ve_schemas = {
    'VisualEditorDOMRetrieved': 'retrieve',
    'VisualEditorDOMSaved': 'save',
}

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


def handle_nav_timing(meta):
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
        if 'loadEventEnd' in event and 'responseEnd' in event:
            event['rendering'] = event['loadEventEnd'] - event['responseEnd']
        if 'loadEventEnd' in event and 'domInteractive' in event:
            event['pageSpeed'] = (
                event['loadEventEnd'] - event['domInteractive'])
        if 'loadEventEnd' in event and 'navigationStart' in event:
            event['totalPageLoadTime'] = (
                event['loadEventEnd'] - event['navigationStart'])

    site = 'mobile' if 'mobileMode' in event else 'desktop'
    auth = 'anonymous' if event.get('isAnon') else 'authenticated'

    bits_cache = meta.get('recvFrom', '').split('.')[0]

    for metric in metrics:
        value = event.get(metric, 0)
        if value > 0 and value < 60000:
            stat = 'browser.%s.%s:%s|ms' % (metric, site, value)
            sock.sendto(stat.encode('utf-8'), addr)
            stat = 'browser.%s.%s.%s:%s|ms' % (metric, site, auth, value)
            sock.sendto(stat.encode('utf-8'), addr)
            stat = 'browser.%s.%s:%s|ms' % (metric, bits_cache, value)
            sock.sendto(stat.encode('utf-8'), addr)


def handle_ve(meta):
    schema = ve_schemas[meta['schema']]
    event = meta['event']
    duration = int(round(event['duration']))
    stat = 'browser.ve.dom.%s:%s|ms' % (schema, duration)
    sock.sendto(stat.encode('utf-8'), addr)
    if schema == 'retrieve':
        if event.get('parsoidCachedResponse', False):
            cache = 'cached'
        else:
            cache = 'uncached'
        stat = 'browser.ve.dom.%s.%s:%s|ms' % (schema, cache, duration)
        sock.sendto(stat.encode('utf-8'), addr)
        stat = 'browser.ve.dom.%s.%s.count:1|c' % (cache, schema)
        sock.sendto(stat.encode('utf-8'), addr)
    stat = 'browser.ve.dom.%s.count:1|c' % schema
    sock.sendto(stat.encode('utf-8'), addr)


for meta in iter(zsock.recv_json, ''):
    if meta['revision'] in schema_revs:
        handle_nav_timing(meta)
    if meta['schema'] in ve_schemas:
        handle_ve(meta)
