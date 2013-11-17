#!/usr/bin/env python

# Sets up Receive Packet Steering (RPS) for a given interface.
#
# Tries to allocate separate queues to separate CPUs, rather than follow
# what's common advice out there (all CPUs to all queues), as experience has
# shown a tremendous difference.
#
# Author: Faidon Liambotis
# Copyright (c) 2013 Wikimedia Foundation, Inc.

import os
import glob
import sys


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

    return rx_queues


def assign_rx_queue_to_cpus(device, rx_queue, cpus):
    """Assign a device's RX queue to a CPU set"""
    bitmask = 0
    for cpu in cpus:
        bitmask += 2**cpu

    rx_node = os.path.join('/sys/class/net', device, 'queues',
                           'rx-%s' % rx_queue, 'rps_cpus')

    write_value(rx_node, format(bitmask, 'x'))


def distribute_rx_queues_to_cpus(device, rx_queues, cpu_list):
    """Performs a smart distribution of RX queues to CPUs (or vice-versa)"""
    if len(rx_queues) >= len(cpu_list):
        # try to divide queues / CPUs and assign N CPUs per queue, isolated
        (quot, rem) = divmod(len(rx_queues), len(cpu_list))

        for i, cpu in enumerate(cpu_list):
            for j in range(quot):
                rxq = rx_queues[i*quot + j]
                assign_rx_queue_to_cpus(device, rxq,  [cpu])

        # if there are remainders, assign CPUs to them and hope for the best
        if rem > 0:
            for i, rxq in enumerate(rx_queues[-rem:]):
                assign_rx_queue_to_cpus(device, rxq,  cpu_list)
    else:
        # do the opposite division
        (quot, rem) = divmod(len(cpu_list), len(rx_queues))

        #...and collect CPUs, then assign them together to queues
        for i, rxq in enumerate(rx_queues):
            cpus = []
            for j in range(quot):
                cpus.append(cpu_list[i*quot + j])
            assign_rx_queue_to_cpus(device, rxq,  cpus)


def main():
    """Simple main() function with sensible defaults"""
    try:
        device = sys.argv[1]
    except IndexError:
        device = 'eth0'

    cpu_list = get_cpu_list()
    rx_queues = get_rx_queues(device)

    distribute_rx_queues_to_cpus(device, rx_queues, cpu_list)


if __name__ == '__main__':
    main()
