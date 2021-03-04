#!/usr/bin/python3

# Check if we there's enough space available to make an lvm partition.
# Succeed if there is, fail with a message if not.
#
# argv[1] can specify the minimum space required for partitioning.

import subprocess
import sys

if len(sys.argv) > 1:
    minsize = float(sys.argv[1])
else:
    minsize = 1.5

pvfree = subprocess.getoutput("pvs --noheadings --units G -o pv_free")
assert pvfree.endswith("G")

freegigs = float(pvfree.rstrip("G").lstrip())

if freegigs >= minsize:
    exit(0)
else:
    exit("Less than %sG is available for partitioning." % minsize)
