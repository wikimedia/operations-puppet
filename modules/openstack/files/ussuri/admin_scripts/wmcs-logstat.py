#!/usr/bin/env python
# encoding: utf-8
"""
logstat.py

# CDDL HEADER START
#
# The contents of this file are subject to the terms of the
# Common Development and Distribution License, Version 1.0 only
# (the "License").  You may not use this file except in compliance
# with the License.
#
# You can obtain a copy of the license at
# http://forgerock.org/license/CDDLv1.0.html.
# See the License for the specific language governing permissions
# and limitations under the License.
#
# When distributing Covered Code, include this CDDL HEADER in each
# file and include the License file at
# trunk/opends/resource/legal-notices/OpenDS.LICENSE.  If applicable,
# add the following below this CDDL HEADER, with the fields enclosed
# by brackets "[]" replaced with your own identifying information:
#      Portions Copyright [yyyy] [name of copyright owner]
#
# CDDL HEADER END
#
#
#      Copyright 2012 ForgeRock Inc.

Created by Ludovic Poitou on 2012-01-10.

This program reads OpenDJ access logs and output statistics.
"""

import sys
import getopt
import re

help_message = '''
Usage: logstat.py [options] file [file ...]
options:
\t -a SLA : specifies the SLA in milliseconds
\t -s operation(s) : specifies which operations to compute stat for.
\t -o output : specifies the output file, otherwise stdout is used
\t -r : include replicated operations
\t -v : verbose mode

'''


class OpStat():

    def __init__(self, type, sla):
        self.type = type
        self.count = long(0)
        self.etime = long(0)
        self.maxEtime = long(0)
        self.SLA = sla
        self.countOverSLA = long(0)
        self.countOver10SLA = long(0)
        self.retEntries = long(0)
        self.count0Entries = long(0)
        self.count1Entry = long(0)
        self.maxEntries = long(0)

    def incEtime(self, etime):
        self.etime += etime
        self.count += 1
        if self.maxEtime < etime:
            self.maxEtime = etime
        if etime > self.SLA:
            self.countOverSLA += 1
        if etime > self.SLA * 10:
            self.countOver10SLA += 1

    def incEntries(self, count):
        self.retEntries += count
        if self.maxEntries < count:
            self.maxEntries = count
        if count == 0:
            self.count0Entries += 1
        if count == 1:
            self.count1Entry += 1

    def printStats(self, outfile):
        if self.count != 0:
            outfile.write(self.type + ":\t" + str(self.count) + "\tAvg: " +
                          str(round(float(self.etime) / float(self.count), 3)) +
                          " ms\tMax: " + str(self.maxEtime) + " ms\t>" + str(self.SLA) + "ms: " +
                          str(self.countOverSLA) +
                          " (" + str(self.countOverSLA * 100 / self.count) + "%)\t>" +
                          str(self.SLA * 10) + "ms: " +
                          str(self.countOver10SLA) +
                          " (" + str(self.countOver10SLA * 100 / self.count) + "%)\n")
        if self.retEntries != 0:
            outfile.write(
                self.type + ":\tReturned " +
                str(round(float(self.retEntries) / float(self.count), 1)) +
                " entries in average, max: " + str(self.maxEntries) +
                ", none: " + str(self.count0Entries) +
                ", single: " + str(self.count1Entry) + "\n")


class Usage(Exception):

    def __init__(self, msg):
        self.msg = msg


def main(argv=None):
    output = ""
    ops = ""
    includeReplOps = False
    sla = 100
    doSearch = True
    doAdd = True
    doBind = True
    doCompare = True
    doDelete = True
    doExtended = True
    doModify = True
    doModDN = True

    if argv is None:
        argv = sys.argv
    try:
        try:
            opts, args = getopt.getopt(argv[1:], "a:ho:rs:v", ["help", "output="])
        except getopt.error as msg:
            raise Usage(msg)

        # option processing
        for option, value in opts:
            if option == "-v":
                pass
            if option == "-r":
                includeReplOps = True
            if option in ("-h", "--help"):
                raise Usage(help_message)
            if option in ("-o", "--output"):
                output = value
            if option in ("-s", "--stats"):
                ops = value
            if option in ("-a", "--agreement"):
                sla = int(value)

    except Usage as err:
        print >> sys.stderr, sys.argv[0].split("/")[-1] + ": " + str(err.msg)
        print >> sys.stderr, "\t for help use --help"
        return 2

    if output != "":
        try:
            outfile = open(output, "w")
        except Usage as err:
            print >> sys.stderr, "Can't open output file: " + str(err.msg)
    else:
        outfile = sys.stdout

    if ops != "":
        doSearch = False
        doAdd = False
        doBind = False
        doCompare = False
        doDelete = False
        doExtended = False
        doModify = False
        doModDN = False
        opers = ops.split(',')
        for op in opers:
            if op == "Search":
                doSearch = True
                continue
            if op == "Add":
                doAdd = True
                continue
            if op == "Bind":
                doBind = True
                continue
            if op == "Compare":
                doCompare = True
                continue
            if op == "Delete":
                doDelete = True
                continue
            if op == "Extended":
                doExtended = True
                continue
            if op == "Modify":
                doModify = True
                continue
            if op == "ModDN":
                doModDN = True
                continue
            print >> sys.stderr, "Invalid op name in stats: " + op + ", ignored"

    searches = OpStat("Search", sla)
    adds = OpStat("Add", sla)
    binds = OpStat("Bind", sla)
    compares = OpStat("Compare", sla)
    deletes = OpStat("Delete", sla)
    extops = OpStat("Extend", sla)
    modifies = OpStat("Modify", sla)
    moddns = OpStat("ModDN", sla)

    for logfile in args:
        try:
            infile = open(logfile, "r")
        except err:
            print >> sys.stderr, "Can't open file: " + str(err.msg)

        outfile.write("processing file: " + logfile + "\n")
        for i in infile:
            if re.search(" conn=-1 ", i) and not includeReplOps:
                continue
            if doSearch and re.search("SEARCH RES", i):
                m = re.match(".*nentries=(\d+) etime=(\d+)", i)
                if m:
                    searches.incEtime(int(m.group(2)))
                    searches.incEntries(int(m.group(1)))
            if doAdd and re.search("ADD RES", i):
                m = re.match(".* etime=(\d+)", i)
                if m:
                    adds.incEtime(int(m.group(1)))
            if doBind and re.search("BIND RES", i):
                m = re.match(".* etime=(\d+)", i)
                if m:
                    binds.incEtime(int(m.group(1)))
            if doCompare and re.search("COMPARE RES", i):
                m = re.match(".* etime=(\d+)", i)
                if m:
                    compares.incEtime(int(m.group(1)))
            if doDelete and re.search("DELETE RES", i):
                m = re.match(".* etime=(\d+)", i)
                if m:
                    deletes.incEtime(int(m.group(1)))
            if doExtended and re.search("EXTENDED RES", i):
                m = re.match(".* etime=(\d+)", i)
                if m:
                    extops.incEtime(int(m.group(1)))
            if doModify and re.search("MODIFY RES", i):
                m = re.match(".* etime=(\d+)", i)
                if m:
                    modifies.incEtime(int(m.group(1)))
            if doModDN and re.search("MODDN RES", i):
                m = re.match(".* etime=(\d+)", i)
                if m:
                    moddns.incEtime(int(m.group(1)))

        # Done processing that file, lets move to next one

    # We're done with all files. Proceed with displaying stats
    adds.printStats(outfile)
    binds.printStats(outfile)
    compares.printStats(outfile)
    deletes.printStats(outfile)
    extops.printStats(outfile)
    modifies.printStats(outfile)
    moddns.printStats(outfile)
    searches.printStats(outfile)
    outfile.write("Done\n")
    outfile.close()


if __name__ == "__main__":
    sys.exit(main())
