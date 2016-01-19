#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
    Gmond module for aggregating and posting udp2log socket stats.

    Notes:
    - If multiple udp2log instances are running, their stats will be
      aggregated.
    - Ori's original script read from /proc/<pid>/fd to
      find socket inodes.  These were used for finding
      socket stats in /proc/net/udp.  ganglia does not have
      read permissions on /proc/<pid>/fd.  Instead, this
      script now finds the udp2log listen port in the
      udp2log command line, and uses that to find socket
      stats in /proc/net/udp.

    Original: https://github.com/atdt/python-udp-gmond

    :copyright: (c) 2012 Wikimedia Foundation
    :author: Ori Livneh <ori@wikimedia.org>
    :license: GPLv2+
"""
from __future__ import print_function

from threading import Timer
import logging
import os
import stat


UPDATE_INTERVAL = 5  # seconds


defaults = {
    "slope": "both",
    "time_max": 60,
    "format": "%d",
    "value_type": "uint",
    "groups": "udp2log",
    "units": "bytes"
}

udp2log_fields = {
    "rx_queue": "udp2log Receive Queue",
    "tx_queue": "udp2log Transmit Queue",
    "drops": "udp2log Dropped Packets"
}


def get_udp2log_ports():
    """Returns the listen ports of running udp2log processes"""
    pattern = "/usr/bin/udp2log"
    ports = []
    for pid in iter_pids():
        cmd = get_cmd(pid)
        if pattern in cmd[0]:
            p_index = False
            try:
                p_index = cmd.index('-p')
            except ValueError, e:
                continue
            ports.append(int(cmd[p_index + 1]))
    return ports


def get_cmd(pid):
    """Get the command-line instantiation for a given process id"""
    with open('/proc/%s/cmdline' % pid, 'rt') as f:
        return f.read().split('\x00')


def iter_pids():
    """Returns an iterator of process ids of all running processes"""
    return (int(node) for node in os.listdir('/proc') if node.isdigit())


def check_udp_sockets():
    """
    Gets the number of packets in each active UDP socket's tx/rx queues and the
    number of dropped packets. Returns a dictionary of dictionaries, keyed to
    socket port, with sub-keys 'tx_queue', 'rx_queue' and 'drops'.
    """
    sockets = {}
    with open('/proc/net/udp', 'rt') as f:
        f.readline()  # Consume and discard header line
        for line in f:
            values = line.replace(':', ' ').split()
            # key by integer port value.
            # e.g. Convert 20E4 hex to int 8420.
            sockets[int(values[2], 16)] = {
                'tx_queue': int(values[6], 16),
                'rx_queue': int(values[7], 16),
                'drops': int(values[16])
            }
    return sockets


def check_udp2log():
    """
    Aggregate data about all running udp2log instances
    """
    aggr = dict(tx_queue=0, rx_queue=0, drops=0)
    ports = get_udp2log_ports()
    for port, status in check_udp_sockets().items():
        # if the udp socket is a udp2log port,
        # aggregate the stats.
        if port in ports:
            aggr['tx_queue'] += status['tx_queue']
            aggr['rx_queue'] += status['rx_queue']
            aggr['drops'] += status['drops']
    return aggr

#
# Gmond Interface
#
stats = {}


def update_stats():
    """Update udp2log stats and schedule the next run"""
    stats.update(check_udp2log())
    logging.info("Updated: %s", stats)
    Timer(UPDATE_INTERVAL, update_stats).start()


def metric_handler(name):
    """Get value of particular metric; part of Gmond interface"""
    return stats[name]


def metric_init(params):
    """Initialize; part of Gmond interface"""
    descriptors = []
    defaults['call_back'] = metric_handler
    for name, description in udp2log_fields.items():
        descriptor = dict(name=name, description=description)
        descriptor.update(defaults)
        if name == 'drops':
            descriptor['units'] = 'packets'
            descriptor['slope'] = 'positive'
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
        print(("%s => " + metric['format']) % (metric['name'], value))
