#!/usr/bin/python
# -*- coding: utf-8 -*-
import string
import sys


def get_sysctl(name):

    path = '/proc/sys/' + name.translate(string.maketrans('.', '/'))

    try:
        with open(path) as f:
            value = f.read().rstrip('\n')
        return int(value)

    except IOError:
        return None


max_value = get_sysctl('net.netfilter.nf_conntrack_max')
if max_value is not None and max_value > 0:
    count_value = get_sysctl('net.netfilter.nf_conntrack_count')
    full = int(count_value/max_value*100)
if full >= 80 and full <= 90:
    print("Warning: nf_conntrack is %d %% full" % (full))
    sys.exit(1)
elif full > 90:
    print("Critical: nf_conntrack is %d %% full" % (full))
    sys.exit(2)
elif full < 80:
    print("OK: nf_conntrack is %d %% full" % (full))
    sys.exit(0)
else:
    print("UNKNOWN: error reading nf_conntrack")
    sys.exit(3)
