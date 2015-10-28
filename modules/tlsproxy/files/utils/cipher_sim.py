#!/usr/bin/env python
# -*- coding: utf-8 -*-

# cipher_sim - Simulate ciphersuite negotation results based on a set of pcap
# files of ClientHello packets from real clients, and an arbitrary
# ssl_ciphersuite string like the ones we configure nginx with (but which may
# be different from our current, live ciphersuite list).
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
# The first part of the process is gathering the live packet data, which can
# then be re-used and re-simulated against different server preference lists:
# The pcap files should be generated with a BPF filter that matches only the
# inbound ClientHello packets, such as:
#
#   dst port 443 \
#     and (tcp[((tcp[12:1] & 0xf0) >> 2)+5:1] = 0x01) \
#     and (tcp[((tcp[12:1] & 0xf0) >> 2):1] = 0x16)
#
# (but note the above would also capture the outbound clienthello of local
# processes connecting outwards from the capturing machine! - could use some
# filtering on the dst ip addresses as well if you want to close that
# loophole).
#
# Several different sniffer utilities can capture with such a BPF filter.
# With "tshark" in non-promiscious mode on eth0 and stopping after 1000
# packets, the command looks like:
#   tshark -n -p -i eth0 -w /tmp/output.cap -c 1000 -f <bpf filter above>
#
# Once you have your capture file(s), move them all to the host you're doing
# the analysis on (as a non-root user!), which needs installed and up-to-date
# working binaries for both "tshark" and "openssl".  Then you feed this script
# the name of all the capture files and the OpenSSL server-side ciphersuite
# setting to simulate, in the same form used in HTTPS server configs, like:
#  '-ALL:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:....'
#
# The output of this script is an ordered list of the negotiated ciphersuites
# by the count and percentage (both displayed) of clients which would have
# negotiated them.  If some clients would have failed negotiation completely
# (no ciphersuites in common), they are listed as the special ciphersuite
# ":HANDSHAKE-FAILURE:".  Be aware that this is only simulating
# cipher-matching, and does not account for other forms of potential handshake
# failure such as DHE>1024 incompatibility.
#
# Full example of real usage (pcap files generated as indicated above...):
# -CUT------------------------
#   bblack@cp1065:~/cipher_work$ fold -w 72 < server_pref # pep8--
#   -ALL:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:DHE-RSA-A
#   ES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA3
#   84:DHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-
#   SHA256:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES256-SH
#   A384:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA:ECDHE-RSA-AES256-SHA
#   :DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-RSA-AES256-SHA256:DHE-RSA-
#   AES256-SHA:DHE-RSA-CAMELLIA128-SHA:DHE-RSA-CAMELLIA256-SHA:AES128-GCM-SH
#   A256:AES256-GCM-SHA384:AES128-SHA256:AES128-SHA:AES256-SHA256:AES256-SHA
#   :DES-CBC3-SHA
#   bblack@cp1065:~/cipher_work$ ls -l capfiles/
#   total 3268
#   -rw-r--r-- 1 bblack wikidev 3031756 Oct 28 12:36 second.cap
#   -rw-r--r-- 1 bblack wikidev  310804 Oct 27 21:13 test.cap
#   bblack@cp1065:~/cipher_work$ ./cipher_sim.py -s server_pref capfiles/*.cap
#   Total ClientHellos             | 10993
#   -----------------------------------------------
#   ECDHE-ECDSA-AES128-GCM-SHA256  | 30.901% (3397)
#   ECDHE-RSA-AES256-GCM-SHA384    | 14.236% (1565)
#   ECDHE-RSA-AES256-SHA384        | 11.789% (1296)
#   ECDHE-ECDSA-AES256-SHA         | 07.814% (859)
#   AES128-SHA                     | 05.695% (626)
#   ECDHE-RSA-AES256-SHA           | 05.494% (604)
#   ECDHE-ECDSA-AES256-SHA384      | 04.776% (525)
#   DHE-RSA-AES256-SHA             | 04.030% (443)
#   ECDHE-RSA-AES128-GCM-SHA256    | 03.812% (419)
#   ECDHE-ECDSA-AES256-GCM-SHA384  | 03.593% (395)
#   DES-CBC3-SHA                   | 02.283% (251)
#   AES128-SHA256                  | 01.674% (184)
#   AES256-SHA                     | 01.355% (149)
#   DHE-RSA-AES128-SHA             | 01.164% (128)
#   ECDHE-ECDSA-AES128-SHA256      | 00.382% (42)
#   ECDHE-ECDSA-AES128-SHA         | 00.373% (41)
#   DHE-RSA-AES256-GCM-SHA384      | 00.337% (37)
#   DHE-RSA-CAMELLIA256-SHA        | 00.109% (12)
#   DHE-RSA-AES256-SHA256          | 00.073% (8)
#   AES256-SHA256                  | 00.036% (4)
#   DHE-RSA-AES128-GCM-SHA256      | 00.036% (4)
#   ECDHE-RSA-AES128-SHA           | 00.027% (3)
#   ECDHE-RSA-AES128-SHA256        | 00.009% (1)
#
# -CUT------------------------

import os
import re
import glob
import argparse
import subprocess
import collections


def get_choice(client_ciphers, server_pref):
    for c in client_ciphers:
        for servc in server_pref:
            if int(c) == servc[0]:
                return servc[1]
    return ":HANDSHAKE-FAILURE:"


def process_pcapfile(pcapf, server_pref):
    cipher_stats = collections.Counter()
    shark_args = [
        'tshark', '-n', '-l', '-Tfields', '-r', pcapf,
        '-e', 'ssl.handshake.ciphersuite',
    ]
    shark = subprocess.Popen(shark_args, stdout=subprocess.PIPE)
    for line in iter(shark.stdout.readline, b''):
        # for some reason there are rare blanks... 0.06% in testing
        # are these just bad hellos, inexactness of BPF filter, ?
        if line != '\n':
            client_cipher_nums = line.rstrip().split(',')
            choice = get_choice(client_cipher_nums, server_pref)
            cipher_stats[choice] += 1
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
    p.add_argument('pcapfiles', nargs=argparse.REMAINDER,
                   help="List of one or more pcap files")

    args = p.parse_args()
    if len(args.pcapfiles) < 1:
        raise Exception('One or more pcap files must be specified!')

    with open(args.serverpref[0], mode='r') as spref_file:
        spref_str = spref_file.read().rstrip()

    return [spref_str, args.pcapfiles]


def main():
    (spref_str, pcapfiles) = parse_options()

    server_pref = load_server_pref(spref_str)
    cipher_stats = collections.Counter()
    # XXX this could be trivially parallelized mapreduce-style per capfile ...
    for pcapf in pcapfiles:
        cipher_stats += process_pcapfile(pcapf, server_pref)

    total = sum(cipher_stats.values())
    print "Total ClientHellos             | %d" % (total)
    print "-----------------------------------------------"
    for kv in cipher_stats.most_common():
        print "%-30s | %06.3f%% (%d)" % \
              (kv[0], 100 * float(kv[1]) / total, kv[1])

if __name__ == '__main__':
    main()

# vim: set ts=4 sw=4 et:
