#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
    Gmond module for aggregating and posting udp2log socket stats. Easily
    adaptable to other processes.

    Notes:
    - If multiple udp2log instances are running, their stats will be
      aggregated.
    - The user running this script must have read rights on the file
      descriptors owned by udp2log.

    TODO (Ori.livneh, 6-Aug-2012): Rather than hard-code udp2log, grab the
    process pattern from 'params' argument to metric_init. If key is missing,
    tally queues / drops for all open UDP sockets.

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
    "slope"      : "both",
    "time_max"   : 60,
    "format"     : "%d",
    "value_type" : "uint",
    "groups"     : "network,udp",
    "units"      : "bytes"
}

udp2log_fields = {
    "rx_queue" : "udp2log Receive Queue",
    "tx_queue" : "udp2log Transmit Queue",
    "drops"    : "udp2log Dropped Packets"
}

def pgrep(pattern):
    """Get a list of process ids whose invocation matches `pattern`"""
    return [pid for pid in iter_pids() if pattern in get_cmd(pid)[0]]


def get_cmd(pid):
    """Get the command-line instantiation for a given process id"""
    with open('/proc/%s/cmdline' % pid, 'rt') as f:
        return f.read().split('\x00')


def iter_pids():
    """Returns an iterator of process ids of running processes"""
    return (int(node) for node in os.listdir('/proc') if node.isdigit())


def iter_fds(pid):
    """Iterate file descriptors owned by process with id `pid`"""
    fd_path = '/proc/%s/fd' % pid
    return (os.path.join(fd_path, fd) for fd in os.listdir(fd_path))


def get_socket_inodes(pid):
    """Get inodes of process's sockets"""
    stats = (os.stat(fd) for fd in iter_fds(pid))
    return [fd_stats.st_ino for fd_stats in stats if
            stat.S_ISSOCK(fd_stats.st_mode)]


def check_udp_sockets():
    """
    Gets the number of packets in each active UDP socket's tx/rx queues and the
    number of dropped packets. Returns a dictionary of dictionaries, keyed to
    socket inodes, with sub-keys 'tx_queue', 'rx_queue' and 'drops'.
    """
    sockets = {}
    with open('/proc/net/udp', 'rt') as f:
        f.readline()  # Consume and discard header line
        for line in f:
            values = line.replace(':', ' ').split()
            sockets[int(values[13])] = {
                'tx_queue' : int(values[6], 16),
                'rx_queue' : int(values[7], 16),
                'drops'    : int(values[16])
            }
    return sockets


def check_udp2log():
    """
    Aggregate data about all running udp2log instances
    """
    inodes = []
    for udp2log_instance in pgrep('udp2log'):
        inodes.extend(get_socket_inodes(udp2log_instance))
    aggr = dict(tx_queue=0, rx_queue=0, drops=0)
    for inode, status in check_udp_sockets().items():
        if inode in inodes:
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
        print(( "%s => " + metric['format'] ) % ( metric['name'], value ))
