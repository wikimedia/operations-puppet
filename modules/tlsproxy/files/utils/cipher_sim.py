#!/usr/bin/env python
# -*- coding: utf-8 -*-

# cipher_sim - Simulate ciphersuite negotation results based on one or more
# aggregated ClientHello data files and an arbitrary server cipher preference
# list.
#
# Copyright 2015 Brandon Black
# Copyright 2015 Wikimedia Foundation, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# ----
# The commandline arguments take the form:
#
#   cat aggegrate_files* | cipher_sim.py -s server_pref_file
#
# Where "server_pref_file" is a file containing a standard OpenSSL ciphersuite
# preference list in the same form used by e.g. nginx's ssl_ciphers parameter
# on a single line, and the standard input contains aggregated clienthello
# stats (possibly catted from several files) formatted with lines as ...
#
# NNN;C1,C2,C3,...
#
# ... where "NNN" is the count of clienthellos of this type seen, and
# "C1,C2,C3,..." is the list of decimal integer ciphers those clienthellos
# indicated.  Example of 54 clienthellos which all specified exactly this list
# of 3 ciphers: "ECDHE-RSA-AES128-SHA, AES128-SHA, DES-CBC3-SHA"
#
# 54;49171,47,10
#
# There are no further requirements on the input data: it can contain repeats
# (which be aggregated up as they're processed), and it can contain duplicates
# in different order (which it would be more efficient to sort and aggregate
# when generating the input, but isn't strictly necessary).  If you're
# concatenating multiple aggregate files from several machines into this
# analysis script, there likely will be all sorts of repeats, and that's ok.
#
# There is a companion shellscript "cipher_cap.sh" designed to generate this
# aggregated captured data efficiently on our cp* cache machine setup today.
#
# The output of this simulator is an ordered list of the negotiated
# ciphersuites by the count and percentage (both displayed) of clients which
# would have negotiated them.  If some clients would have failed negotiation
# completely (no ciphersuites in common), they are listed as the special
# ciphersuite ":HANDSHAKE-FAILURE:".  Be aware that this is only simulating
# cipher-matching, and does not account for other forms of potential handshake
# failure such as DHE>1024 incompatibility.
#
# There is also currently a special outout ":TSHARK_BLANK:" to indicate counts
# of no cipher list at all (e.g. "54;"), which currently happens in small
# numbers with the current capture script for unknown reasons...

import os
import re
import sys
import argparse
import subprocess
import collections


def get_choice(client_ciphers, server_pref):
    for servc in server_pref:
        for c in client_ciphers:
            if int(c) == servc[0]:
                return servc[1]
    return ":HANDSHAKE-FAILURE:"


def process_stdin(server_pref):
    cipher_stats = collections.Counter()
    for line in sys.stdin.readlines():
        (ct, clist) = line.rstrip().split(';')
        if len(clist):
            cnums = clist.split(',')
            choice = get_choice(cnums, server_pref)
        else:
            choice = ":TSHARK_BLANK:"
        cipher_stats[choice] += int(ct)
    return cipher_stats


def load_server_pref(pref_str):
    server_pref = []
    ossl_out = subprocess.check_output([
        'openssl', 'ciphers', '-V', pref_str
    ])
    matcher = re.compile('^ *0x([0-9A-F]{2}),0x([0-9A-F]{2}) - ([^ ]+) ')
    for ossl_line in ossl_out.splitlines():
        result = matcher.match(ossl_line)
        if not result:
            raise Exception("Regex failed on openssl output: >> %s <<"
                            % (ossl_line))
        # This converts e.g. 0xC0,0x2B -> 49195
        cnum = (int(result.group(1), 16) * 256) + int(result.group(2), 16)
        server_pref.append([
            cnum,
            result.group(3)
        ])
    return server_pref


def file_exists(fname):
    """Helper for argparse to do check if a filename argument exists"""
    if not os.path.exists(fname):
        raise argparse.ArgumentTypeError("{0} does not exist".format(fname))
    return fname


def parse_options():
    p = argparse.ArgumentParser(description='Ciphersuite Simulator')
    p.add_argument('--serverpref', '-s', dest='serverpref', required=True,
                   metavar="FILE", nargs=1, type=file_exists,
                   help="File containing server cipher pref string")

    args = p.parse_args()
    with open(args.serverpref[0], mode='r') as spref_file:
        spref_str = spref_file.read().rstrip()

    return spref_str


def main():
    spref_str = parse_options()
    server_pref = load_server_pref(spref_str)
    cipher_stats = process_stdin(server_pref)
    total = sum(cipher_stats.values())
    print "Total ClientHellos             | %d" % (total)
    print "-----------------------------------------------"
    for kv in cipher_stats.most_common():
        print "%-30s | %06.3f%% (%d)" % \
              (kv[0], 100 * float(kv[1]) / total, kv[1])

if __name__ == '__main__':
    main()

# vim: set ts=4 sw=4 et:
