#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
    Python Gmond Module for UDP Statistics
    Original: https://github.com/atdt/python-udp-gmond

    :copyright: (c) 2012 Wikimedia Foundation
    :author: Ori Livneh <ori@wikimedia.org>
    :license: GPL
    
"""
from __future__ import print_function

import logging
from ast import literal_eval
from threading import Timer


UPDATE_INTERVAL = 5  # seconds

defaults = {
    "slope"      : "both",
    "time_max"   : 60,
    "format"     : "%u",
    "value_type" : "uint",
    "groups"     : "network,udp",
    "units"      : "packets"
}

udp_fields = {
    "InDatagrams"  : "UDP Packets Received",
    "NoPorts"      : "UDP Packets to Unknown Port Received",
    "InErrors"     : "UDP Packet Receive Errors",
    "OutDatagrams" : "UDP Packets Sent",
    "RcvbufErrors" : "UDP Receive Buffer Errors",
    "SndbufErrors" : "UDP Send Buffer Errors"
}

netstats = {}


def get_netstats():
    """Parse /proc/net/snmp"""
    with open('/proc/net/snmp', 'rt') as snmp:
        raw = {}
        for line in snmp:
            key, vals = line.split(':', 1)
            key = key.lower()
            vals = vals.strip().split()
            raw.setdefault(key, []).append(vals)
    return dict((k, dict(zip(*vs))) for (k, vs) in raw.items())


def update_stats():
    """Update netstats and schedule the next run"""
    netstats.update(get_netstats())
    logging.info("Updated: %s", netstats['udp'])
    Timer(UPDATE_INTERVAL, update_stats).start()


def metric_handler(name):
    """Get value of particular metric; part of Gmond interface"""
    logging.debug('metric_handler(): %s', name)
    return literal_eval(netstats['udp'][name])


def metric_init(params):
    """Initialize; part of Gmond interface"""
    descriptors = []
    defaults['call_back'] = metric_handler
    for name, description in udp_fields.items():
        descriptor = dict(name=name, description=description)
        descriptor.update(defaults)
        descriptors.append(descriptor)
    update_stats()
    return descriptors


def metric_cleanup():
    """Teardown; part of Gmond interface"""
    pass


if __name__ == '__main__':
    # When invoked as standalone script, run a self-test by querying each
    # metric descriptor and printing it out.
    logging.basicConfig(level=logging.DEBUG)
    for metric in metric_init({}):
        value = metric['call_back'](metric['name'])
        print(( "%s => " + metric['format'] ) % ( metric['name'], value ))
