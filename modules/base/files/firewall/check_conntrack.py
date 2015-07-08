#!/usr/bin/python
# -*- coding: utf-8 -*-
from __future__ import division
import sys


def get_sysctl(name):

    path = "/proc/sys/" + name

    try:
        with open(path) as f:
            value = f.read().rstrip('\n')
        return int(value)

    except IOError:
        return None
if len(sys.argv) != 3:
    print "Usage:"
    print "check_conntrack WARNING CRITICAL"
    sys.exit(-1)

warning_threshold = int(sys.argv[1])
critical_threshold = int(sys.argv[2])

#get the values and verify they are not None
max_value = get_sysctl('net/netfilter/nf_conntrack_max')
if max_value is not None and max_value > 0:
    count_value = get_sysctl('net/netfilter/nf_conntrack_count')
    full = int(count_value/max_value*100)
else:
    print("Warning: could not read sysctl settings")
    sys.exit(1)

#check what is the value of full and act upon it
if full >= warning_threshold and full <= critical_threshold:
    print("Warning: nf_conntrack is %d %% full" % (full))
    sys.exit(1)
elif full > critical_threshold or max_value == 0:
    print("Critical: nf_conntrack is %d %% full" % (full))
    sys.exit(2)
elif full < warning_threshold:
    print("OK: nf_conntrack is %d %% full" % (full))
    sys.exit(0)
else:
    print("UNKNOWN: error reading nf_conntrack")
    sys.exit(3)
