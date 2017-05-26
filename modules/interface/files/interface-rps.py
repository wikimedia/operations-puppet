#!/usr/bin/env python

# Sets up scalable network stuff (RPS/RSS/XPS) for a given interface.
#
# For basic technical background:
# https://www.kernel.org/doc/Documentation/networking/scaling.txt
#
# Tries to allocate separate queues to separate CPUs, rather than follow
# what's common advice out there (all CPUs to all queues), as experience has
# shown a tremendous difference.  This attempts to configure all of RPS, RSS,
# and XPS if possible using matching queue/IRQ arrangements.  It's aware of
# hyperthreading and only maps one IRQ/queue per physical cpu core, using only
# the first virtual core of each hyperthread sibling pair.
#
# The only param is the ethernet device name (e.g. 'eth0') and is required.
#
# If the file /etc/interface-rps.d/$device exists, it will be parsed with
# ConfigParser for an Options section to specify additional parameters for
# this interface.  Current options:
#
# rss_pattern - This specifies an optional RSS (Receive Side Scaling) IRQ name
#     regex for finding device IRQs in /proc/interrupts.  It must contain a
#     single '%%d' to match the queue number in the IRQ name.  For example,
#     for bnx2x this is 'eth0-fp-%%d', and for bnx2 and tg3 it is 'eth0-%%d'.
#     The double-percent form is due to ConfigParser limitations.
#
# qdisc - This specifies an optional transmit qdisc (and its parameters) as a
#     single string.  If this script (oddly) found less than two hardware
#     queues for XPS, the specified qdisc will be configured on the device
#     root.  In the normal (2+ queues) case, it will set up "mq" as the root
#     qdisc and use the specified qdisc for each sub-queue within mq.
#
# If the rss_pattern option is not specified, the code will try to auto-detect
# the pattern by searching /proc/interrupts for the 0th RSS IRQ based on the
# supplied device name, e.g. /eth0[^\s0-9]+0$/.  If detection fails, RSS will
# not be set up.
#
# The Transmit Packet Steering (XPS) queue support is limited.  There are only
# two XPS cases currently covered: generic support for assuming 1:1 tx:rx
# mapping if the queue counts look even (which works for at least bnx2), and
# special support for bnx2x:
#
# For cards driven by bnx2x which appear to have a set of tx queues that match
# up with 3x CoS bands multiplied by the rx queue count, we enable XPS and
# group the bands as appropriate.  This is the behavior exhibited by current
# bnx2x drivers that have working XPS implementations (e.g. in the Ubuntu
# 3.13.0-30 kernel), on our hardware and config.  The CoS band count could
# vary on different bnx2x cards, and depending on whether you're using stuff
# like iSCSI/FCoE.  I don't yet know of a way to simply query the CoS band
# count or tx queue mapping directly at runtime from the driver.
#
# Different cards/drivers will likely have different XPS mappings that will
# need to be addressed individually when we encounter them.
#
# Config example:
# -----cut------
# [Options]
# rss_pattern = eth0-%%d
# qdisc = fq flow_limit 300 buckets 8192 maxrate 1gbit
# -----cut------
#
# Authors: Faidon Liambotis and Brandon Black
# Copyright (c) 2013-2017 Wikimedia Foundation, Inc.

import os
import glob
import sys
import re
import warnings
import ConfigParser
import subprocess


def get_value(path):
    """Read a (sysfs) value from path"""
    return open(path, 'r').read()[:-1]


def write_value(path, value):
    """Write a (sysfs) value to path"""
    print '%s = %s' % (path, value)
    open(path, 'w').write(value)


def cmd_nofail(cmd):
    """echo + exec cmd with normal output, raises on rv!=0"""
    print 'Executing: %s' % cmd
    subprocess.check_call(cmd, shell=True)


def cmd_failable(cmd):
    """echo + exec cmd with normal output, ignores errors"""
    print 'Executing: %s' % cmd
    subprocess.call(cmd, shell=True)


def get_cpu_list():
    """Get a list of all CPUs by their number (e.g. [0, 1, 2, 3])"""
    path_cpu = '/sys/devices/system/cpu/'
    cpu_nodes = glob.glob(os.path.join(path_cpu, 'cpu[0-9]*'))
    cpus = [int(os.path.basename(c)[3:]) for c in cpu_nodes]

    # filter-out HyperThreading siblings
    cores = []
    for cpu in cpus:
        path_threads = os.path.join(path_cpu, 'cpu%d' % cpu,
                                    'topology', 'thread_siblings_list')
        thread_siblings = get_value(path_threads).split(',')
        cores.append(int(thread_siblings[0]))

    # return a (unique) sorted set of CPUs without their HT siblings
    return sorted(set(cores))


def get_queues(device, qtype):
    """Get a list of rx or tx queues for device"""
    nodes = glob.glob(os.path.join('/sys/class/net', device, 'queues',
                                   '%s-*' % qtype))
    queues = [int(os.path.basename(q)[3:]) for q in nodes]

    return sorted(queues)


def get_bnx2x_cos_queue_map(tx_queues, rx_queues):
    """Map tx:rx queues based on 3x CoS bands, if things look sane"""

    # bnx2x with working XPS should have 3 tx queues for every rx queue,
    #  representing CoS bands.  So for example if there are 4 rx queues,
    #  the correct mapping will be 12 tx queues with mapping:
    #  { 0: [0, 4, 8], 1: [1, 5, 9], 2: [2, 6, 10], 3: [3, 7, 11] }

    cos_bands = 3
    if len(rx_queues) * cos_bands != len(tx_queues):
        warnings.warn('bnx2x XPS CoS queue map invalid (upgrade driver?)')
        return None

    tx_qmap = {}
    for rxq in rx_queues:
        tx_qmap[rxq] = [rxq + (c * len(rx_queues)) for c in range(cos_bands)]
    return tx_qmap


def detect_rss_pattern(device):
    """Detect RSS IRQ Name pattern based on device, if possible"""

    rss_patt_re = re.compile(r'^\s*[0-9]+:.*\s' + device + r'([^\s0-9]+)0\n$')
    irq_file = open('/proc/interrupts', 'r')
    for line in irq_file:
        match = rss_patt_re.match(line)
        if match:
            return device + match.group(1) + '%d'
    return None


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
            irqs[int(match.group(2))] = int(match.group(1))

    # If we don't get an *exact* match for the rx_queues list, give up
    if len(irqs) != len(rx_queues):
        raise Exception('RSS IRQ count mismatch for pattern %s' % rss_pattern)
    for rxq in rx_queues:
        if rxq not in irqs:
            raise Exception('RSS IRQ missing for queue %d' % rxq)

    # Return a dict of rxq:rx_irq that matches rx_queues
    return irqs


def set_cpus(device, cpus, rxq, rx_irq, txqs):
    """Assign a device's matching set of [rt]x queues and IRQ to a CPU set"""
    bitmask = 0
    for cpu in cpus:
        bitmask += 2 ** cpu
    txt_bitmask = format(bitmask, 'x')

    if rx_irq:
        irq_node = '/proc/irq/%d/smp_affinity' % rx_irq
        write_value(irq_node, txt_bitmask)

    rx_node = '/sys/class/net/%s/queues/rx-%d/rps_cpus' % (device, rxq)
    write_value(rx_node, txt_bitmask)

    if txqs:
        for i in txqs:
            tx_node = '/sys/class/net/%s/queues/tx-%d/xps_cpus' % (device, i)
            write_value(tx_node, txt_bitmask)


def dist_queues_to_cpus(device, cpu_list, rx_queues, rx_irqs, tx_qmap):
    """Smart distribution of queues + IRQs to CPUs (or vice-versa)"""
    if len(rx_queues) >= len(cpu_list):
        # try to divide queues / CPUs and assign N CPUs per queue, isolated
        (quot, rem) = divmod(len(rx_queues), len(cpu_list))

        for i, cpu in enumerate(cpu_list):
            for j in range(quot):
                rxq = rx_queues[i * quot + j]
                set_cpus(device, [cpu], rxq, rx_irqs[rxq], tx_qmap[rxq])

        # if there are remainder queues, split CPU list into rem subgroups
        # (with trailing remainder of CPUs left out), one per queue
        if rem > 0:
            cquot = len(cpu_list) / rem
            for i, rxq in enumerate(rx_queues[-rem:]):
                cpu_sublist = cpu_list[i * cquot:(i + 1) * cquot]
                set_cpus(device, cpu_sublist, rxq, rx_irqs[rxq], tx_qmap[rxq])

    else:
        # do the opposite division
        (quot, rem) = divmod(len(cpu_list), len(rx_queues))

        # ...and collect CPUs, then assign them together to queues
        for i, rxq in enumerate(rx_queues):
            cpus = []
            for j in range(quot):
                cpus.append(cpu_list[i * quot + j])
            set_cpus(device, cpus, rxq, rx_irqs[rxq], tx_qmap[rxq])


def setup_qdisc(device, num_queues, qdisc):
    """Sets up transmit qdiscs"""
    cmd_failable('/sbin/tc qdisc del dev %s root' % device)
    if num_queues < 2:
        cmd_nofail('/sbin/tc qdisc add dev %s root handle 100: %s'
                   % (device, qdisc))
    else:
        cmd_nofail('/sbin/tc qdisc add dev %s root handle 100: mq' % (device))
        for slot in range(1, num_queues + 1):
            cmd_nofail('/sbin/tc qdisc add dev %s handle %x: parent 100:%x %s'
                       % (device, slot, slot, qdisc))


def get_options(device):
    """Get configured options from /etc/interface-rps.d/$device"""

    opts = {
        'rss_pattern': None,
        'qdisc':       None,
    }
    config_file = os.path.join('/etc/interface-rps.d/', device)
    if os.path.isfile(config_file):
        config = ConfigParser.SafeConfigParser()
        config.read(config_file)
        if config.has_option('Options', 'rss_pattern'):
            opts['rss_pattern'] = config.get('Options', 'rss_pattern')
        if config.has_option('Options', 'qdisc'):
            opts['qdisc'] = config.get('Options', 'qdisc')

    return opts


def main():
    """Simple main() function with sensible defaults"""
    try:
        device = sys.argv[1]
    except IndexError:
        device = 'eth0'

    opts = get_options(device)

    if opts['rss_pattern']:
        rss_pattern = opts['rss_pattern']
    else:
        rss_pattern = detect_rss_pattern(device)

    cpu_list = get_cpu_list()
    rx_queues = get_queues(device, 'rx')
    tx_queues = get_queues(device, 'tx')
    driver = os.path.basename(
        os.readlink('/sys/class/net/%s/device/driver/module' % device)
    )

    if rss_pattern:
        if rss_pattern.count('%') != 1 or rss_pattern.count('%d') != 1:
            raise Exception('The RSS pattern must contain a single %d')
        rx_irqs = get_rx_irqs(rss_pattern, rx_queues)
    else:
        rx_irqs = {rxq: None for rxq in rx_queues}

    tx_queue_map = None
    if driver == 'bnx2x':
        tx_queue_map = get_bnx2x_cos_queue_map(tx_queues, rx_queues)
    # Some cards are very simple (e.g. bnx2); assume if counts match
    #   then the queues must map 1:1
    elif len(tx_queues) == len(rx_queues):
        tx_queue_map = {rxq: [rxq] for rxq in rx_queues}

    # This catches the case that a driver-specific txq mapper returned
    #   None due to some validation failure
    if tx_queue_map is None:
        tx_queue_map = {rxq: None for rxq in rx_queues}

    dist_queues_to_cpus(device, cpu_list, rx_queues, rx_irqs, tx_queue_map)
    if opts['qdisc']:
        setup_qdisc(device, len(tx_queues), opts['qdisc'])


if __name__ == '__main__':
    main()
