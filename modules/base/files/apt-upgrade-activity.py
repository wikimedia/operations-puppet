#! /usr/bin/python
# -*- coding: utf-8 -*-

"""
Displays the amount of packages that have been updated or installed on
a system per month (this also accounts for installed packages since some
upgrades may install a new binary package). This operates on apt's log
files, so this only displays the update activity until the last reimage
Passing the parameter --top10 also displays the ten packages which have
been upgraded most often.
"""

import sys
import os
import gzip
import glob
import re
import collections
import dateutil.parser

if os.geteuid() != 0:
    print "needs to be run as root"
    sys.exit(1)

history_files = glob.glob("/var/log/apt/history*")

months = collections.defaultdict(int)
package_update_count = collections.defaultdict(int)

for history_file in history_files:
    if history_file.endswith(".gz"):
        f = gzip.open(history_file, "r")
    else:
        f = open(history_file, "r")

    for i in f.readlines():
        if not i or i == "\n":
            continue
        header, value = i.split(":", 1)
        if header == "Start-Date":
            month = dateutil.parser.parse(value).date().strftime("%Y-%m")
        elif header in ("Upgrade", "Install"):
            # Strip the information on the versions which were upgraded (noted in brackets):
            updated_packages = 0
            for package in re.sub('\(.*?\)', '', value.strip()).split(","):
                updated_packages += 1
                package_update_count[package.strip()] += 1
            months[month] += updated_packages

for i in sorted(months):
    print i, months[i]

if len(sys.argv) > 1 and sys.argv[1] == "--top10":
    print
    package_amount = len(package_update_count)
    cnt = 0

    for key, value in sorted(package_update_count.iteritems(), key=lambda(k, v): (v, k)):
        cnt += 1
        if package_amount - 10 - cnt < 0:
            print "%s: %s" % (key, value)
