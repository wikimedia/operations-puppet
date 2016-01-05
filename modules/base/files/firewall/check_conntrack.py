#!/usr/bin/python
# -*- coding: utf-8 -*-
from __future__ import division
import sys
import os


def get_sysctl(name):

    path = os.path.join('/proc/sys', name)

    try:
        with open(path) as f:
            value = f.read().rstrip('\n')
        return int(value)
    except IOError:
        return None


def main():
    if len(sys.argv) != 3:
        print "Usage:"
        print "check_conntrack WARNING CRITICAL"
        sys.exit(-1)

    w = int(sys.argv[1])
    c = int(sys.argv[2])

    # get the values and verify they are not None
    max_value = get_sysctl('net/netfilter/nf_conntrack_max')
    if max_value is None or max_value < 0:
        print("WARNING: could not read sysctl settings")
        sys.exit(1)

    count_value = get_sysctl('net/netfilter/nf_conntrack_count')
    full = int(count_value / max_value * 100)

    # check what is the value of full and act upon it
    if full >= c:
        print("CRITICAL: nf_conntrack is %d %% full" % full)
        sys.exit(2)
    elif full >= w and full < c:
        print("WARNING: nf_conntrack is %d %% full" % full)
        sys.exit(1)
    elif full < w:
        print("OK: nf_conntrack is %d %% full" % full)
        sys.exit(0)
    else:
        print("UNKNOWN: error reading nf_conntrack")
        sys.exit(3)

if __name__ == '__main__':
    main()
