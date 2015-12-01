#!/usr/bin/env python
# -*- coding: utf-8 -*-
# Copyright (c) 2013 Bryan Davis and Wikimedia Foundation. All Rights Reserved.
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
"""Gmond module for vhtcpd statistics

:copyright: (c) 2013 Bryan Davis and Wikimedia Foundation. All Rights Reserved.
:author: Bryan Davis <bd808@wikimedia.org>
:license: GPL
"""

import time
import copy

CONF = {
    'log': '/tmp/vhtcpd.stats',
    'prefix': 'vhtcpd_',
    'cache_secs': 30,
    'groups': 'vhtcpd',
}
METRICS = {
    'time': 0,
    'data': {
        'uptime': 0,
        'inpkts_recvd': 0,
        'inpkts_sane': 0,
        'inpkts_enqueued': 0,
        'inpkts_dequeued': 0,
        'queue_overflows': 0,
        'queue_size': 0,
        'queue_max_size': 0,
    }
}
LAST_METRICS = copy.deepcopy(METRICS)


def build_desc(skel, prop):
    """Build a description dict from a template.

    :param skel: template dict
    :param prop: substitution dict
    :returns: New dict
    """
    d = skel.copy()
    for k, v in prop.iteritems():
        d[k] = v
    return d
# end build_desc


def get_metrics():
    """Return all metrics"""
    global METRICS, LAST_METRICS

    if (time.time() - METRICS['time']) > CONF['cache_secs']:
        # cache stale, re-read the source file
        with open(CONF['log'], 'rb') as log_file:
            raw = log_file.read()

        metrics = {}
        for chunk in raw.split():
            (k, v) = chunk.split(':', 2)
            try:
                metrics[k] = int(v)
            except ValueError:
                metrics[k] = 0

        # update cache
        LAST_METRICS = copy.deepcopy(METRICS)
        METRICS = {
            'time': time.time(),
            'data': metrics,
        }

    return [METRICS, LAST_METRICS]
# end get_metrics


def clean_name(name):
    """Strip prefix from metric name."""
    return name[len(CONF['prefix']):]
# end clean_name


def get_value(name):
    """Get the current value for a metric."""
    metrics = get_metrics()[0]
    name = clean_name(name)
    try:
        val = metrics['data'][name]
    except StandardError:
        val = 0
    return val
# end get_value


def get_delta(name):
    """Get the delta since last sample for a metric."""
    (curr, last) = get_metrics()

    name = clean_name(name)
    try:
        delta = curr['data'][name] - last['data'][name]
    except StandardError:
        delta = 0
    return delta
# end get_delta


def metric_init(params):
    """Initialize module at gmond startup."""

    global CONF

    for k, v in params.iteritems():
        CONF[key] = v

    skel = {
        'name': 'XXX',
        'call_back': 'XXX',
        'time_max': 60,
        'value_type': 'uint',
        'units': 'XXX',
        'slope': 'positive',        # RRD 'COUNTER' type
        'format': '%d',
        'description': 'XXX',
        'groups': CONF['groups'],
    }

    descriptors = []
    descriptors.append(build_desc(skel, {
        'name': CONF['prefix'] + 'start',
        'call_back': get_value,
        'units': 'epoch',
        'slope': 'zero',
        'description': 'Time service started',
        }))
    descriptors.append(build_desc(skel, {
        'name': CONF['prefix'] + 'uptime',
        'call_back': get_value,
        'units': 's',
        'description': 'Service uptime',
        }))
    descriptors.append(build_desc(skel, {
        'name': CONF['prefix'] + 'inpkts_recvd',
        'call_back': get_value,
        'units': 'pkts',
        'description': 'Multicast packets',
        }))
    descriptors.append(build_desc(skel, {
        'name': CONF['prefix'] + 'inpkts_sane',
        'call_back': get_value,
        'units': 'pkts',
        'description': 'Sane packets',
        }))
    descriptors.append(build_desc(skel, {
        'name': CONF['prefix'] + 'inpkts_enqueued',
        'call_back': get_value,
        'units': 'pkts',
        'description': 'Pakets enqueued',
        }))
    descriptors.append(build_desc(skel, {
        'name': CONF['prefix'] + 'inpkts_dequeued',
        'call_back': get_value,
        'units': 'pkts',
        'description': 'Packets dequeued',
        }))
    descriptors.append(build_desc(skel, {
        'name': CONF['prefix'] + 'queue_overflows',
        'call_back': get_value,
        'units': 'count',
        'description': 'Number of queue overflows',
        }))
    descriptors.append(build_desc(skel, {
        'name': CONF['prefix'] + 'queue_size',
        'call_back': get_value,
        'units': 'count',
        'slope': 'both',                                # RRD 'GAUGE' type
        'description': 'Number of packets in queue',
        }))
    descriptors.append(build_desc(skel, {
        'name': CONF['prefix'] + 'queue_max_size',
        'call_back': get_value,
        'units': 'count',
        'description':
            'Maximum number of packets in queue since startup/overflow',
        }))

    return descriptors
# end metric_init


def metric_cleanup():
    """Clean up on gmond shutdown."""
    pass
# end metric_cleanup


if __name__ == '__main__':
    descriptors = metric_init({})
    for d in descriptors:
        v = d['call_back'](d['name'])
        print 'value for %s is %u' % (d['name'], v)
