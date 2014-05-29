#!/usr/bin/env python

# Sets up Receive Packet Steering (RPS) for a given interface.
#
# Tries to allocate separate queues to separate CPUs, rather than follow
# what's common advice out there (all CPUs to all queues), as experience has
# shown a tremendous difference.
#
# Also sets up matching Receive Side Scaling (RSS) IRQ affinities if
# given a second parameter for lookups in /proc/interrupts.  e.g. for
# bnx2x, this would be "eth0-fp-%d".
#
# Authors: Faidon Liambotis and Brandon Black
# Copyright (c) 2013-2014 Wikimedia Foundation, Inc.

import os
import glob
import sys
import re


def get_value(path):
    """Read a (sysfs) value from path"""
    return open(path, 'r').read()[:-1]


def write_value(path, value):
    """Write a (sysfs) value to path"""
    print '%s = %s' % (path, value)
    open(path, 'w').write(value)


def get_cpu_list():
    """Get a list of all CPUs by their number (e.g. [0, 1, 2, 3])"""
    path_cpu = '/sys/devices/system/cpu/'
    cpu_nodes = glob.glob(os.path.join(path_cpu, 'cpu[0-9]*'))
    cpus = [int(os.path.basename(c)[3:]) for c in cpu_nodes]

    # filter-out HyperThreading siblings
    cores = []
    for cpu in cpus:
        path_threads = os.path.join(path_cpu, 'cpu%s' % cpu,
                                    'topology', 'thread_siblings_list')
        thread_siblings = get_value(path_threads).split(',')
        cores.append(int(thread_siblings[0]))

    # return a (unique) sorted set of CPUs without their HT siblings
    return sorted(set(cores))


def get_rx_queues(device):
    """Get a list of RX queues for device"""
    rx_nodes = glob.glob(os.path.join('/sys/class/net', device, 'queues',
                                      'rx-*'))
    rx_queues = [int(os.path.basename(q)[3:]) for q in rx_nodes]

    return sorted(rx_queues)


def get_rx_irqs(rss_pattern, rx_queues):
    """Find RSS IRQs for rx queues matching rss_pattern (e.g. 'eth0-fp-%d')"""

    # create a dictionary of rxq:rx_irq, e.g.
    #   { 0: '128', 1: '129', 2: '130', ... }
    irqs = {}
    rss_pat_asre = re.sub('%d', r'(\d+)', rss_pattern)
    rss_re = re.compile(r'^\s*([0-9]+):.*\s' + rss_pat_asre + r'\n$')
    irq_file = open('/proc/interrupts', 'r')
    for line in irq_file:
        match = rss_re.match(line)
        if match:
            irqs[int(match.group(2))] = match.group(1)

    # If we don't get an *exact* match for the rx_queues list, give up
    if len(irqs) != len(rx_queues):
        raise Exception('RSS IRQ count mismatch for pattern %s' % rss_pattern)
    for rxq in rx_queues:
        if rxq not in irqs:
            raise Exception('RSS IRQ missing for queue %d' % rxq)

    # Return a dict of rxq:rx_irq that matches rx_queues
    return irqs


def assign_rx_queue_to_cpus(device, cpus, rx_queue, rx_irq):
    """Assign a device's RX queue to a CPU set"""
    bitmask = 0
    for cpu in cpus:
        bitmask += 2**cpu

    rx_node = os.path.join('/sys/class/net', device, 'queues',
                           'rx-%s' % rx_queue, 'rps_cpus')
    write_value(rx_node, format(bitmask, 'x'))

    if rx_irq:
            irq_node = '/proc/irq/%s/smp_affinity' % rx_irq
            write_value(irq_node, format(bitmask, 'x'))


def distribute_rx_queues_to_cpus(device, cpu_list, rx_queues, rx_irqs):
    """Performs a smart distribution of RX queues to CPUs (or vice-versa)"""
    if len(rx_queues) >= len(cpu_list):
        # try to divide queues / CPUs and assign N CPUs per queue, isolated
        (quot, rem) = divmod(len(rx_queues), len(cpu_list))

        for i, cpu in enumerate(cpu_list):
            for j in range(quot):
                rxq = rx_queues[i*quot + j]
                assign_rx_queue_to_cpus(device, [cpu], rxq, rx_irqs[rxq])

        # if there are remainder queues, split CPU list into rem subgroups
        # (with trailing remainder of CPUs left out), one per queue
        if rem > 0:
            cquot = len(cpu_list)/rem
            for i, rxq in enumerate(rx_queues[-rem:]):
                cpu_sublist = cpu_list[i * cquot:(i + 1) * cquot]
                assign_rx_queue_to_cpus(device, cpu_sublist, rxq, rx_irqs[rxq])

    else:
        # do the opposite division
        (quot, rem) = divmod(len(cpu_list), len(rx_queues))

        # ...and collect CPUs, then assign them together to queues
        for i, rxq in enumerate(rx_queues):
            cpus = []
            for j in range(quot):
                cpus.append(cpu_list[i*quot + j])
            assign_rx_queue_to_cpus(device, cpus, rxq, rx_irqs[rxq])


def main():
    """Simple main() function with sensible defaults"""
    try:
        device = sys.argv[1]
    except IndexError:
        device = 'eth0'

    try:
        rss_pattern = sys.argv[2]
    except IndexError:
        rss_pattern = None

    cpu_list = get_cpu_list()
    rx_queues = get_rx_queues(device)

    if rss_pattern:
        if rss_pattern.count('%') != 1 or rss_pattern.count('%d') != 1:
            raise Exception('The RSS pattern must contain a single %d')
        rx_irqs = get_rx_irqs(rss_pattern, rx_queues)
    else:
        # fill in a dict of None to simplify distribution code
        rx_irqs = {rxq: None for rxq in rx_queues}

    distribute_rx_queues_to_cpus(device, cpu_list, rx_queues, rx_irqs)

if __name__ == '__main__':
    main()
