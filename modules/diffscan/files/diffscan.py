#!/usr/bin/python2

# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
# Copyright (c) 2015 Mozilla Corporation
# Author: ameihm@mozilla.com

import calendar
import cPickle
import errno
import fcntl
import getopt
import os
import re
import shutil
import subprocess
import sys
import tempfile
import time

from string import Template

# Edit the nmap_scanoptions variable below to configure generic options
# that are passed by nmap to the script. This script generates email using
# the sendmail command, so also ensure that command is in your path when
# it is run.

# Change this to suit your environment
#
# Be sure to include -vv so hosts that are down are reported in the
# output for correct tracking.
nmap_scanoptions = '-vv -sS -PE -PS22,25,80,443,3306,8443,9100 -T4 ' + \
        '--privileged'

nmap_topports = Template('--top-ports $topports')
nmap_logoptions = Template('-oG $tmppath')
nmap_inoptions = Template('-iL $inpath')
nmap_portspec = Template('-p $portspec')

append_path = ':/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:' + \
        '/usr/local/sbin:/usr/lib'


class ScanData(object):
    def __init__(self):
        self.scantime = time.gmtime()
        self.hosts = {}
        self.dnsmap = {}
        self.uphosts = []
        self.downhosts = []

    def get_hosts(self):
        return self.hosts.keys()

    def get_host_ports(self, h):
        return self.hosts[h]

    def open_exists(self, addr, port, proto):
        if addr not in self.hosts:
            return False
        cand = [port, proto]
        if cand not in self.hosts[addr]:
            return False
        return True

    def total_services(self):
        ret = 0
        for i in self.hosts:
            ret += len(self.hosts[i])
        return ret

    def add_open(self, addr, port, proto, hn):
        if proto != 'tcp' and proto != 'udp':
            raise Exception('unknown protocol %s' % proto)
        if addr not in self.hosts:
            self.hosts[addr] = []
        self.dnsmap[addr] = hn
        self.hosts[addr].append([int(port), proto])


class Alert(object):

    def __init__(self, host, port, proto, dns, open_prev, closed_prev, statstr):
        self.host = host
        self.port = port
        self.proto = proto
        self.dns = dns
        self.open_prev = open_prev
        self.closed_prev = closed_prev
        self.statstr = statstr

    @staticmethod
    def alert_header():
        return 'STATUS HOST PORT PROTO OPREV CPREV DNS'

    def __str__(self):
        return '%s %s %s %s %s %s %s' % (
            self.statstr, self.host,
            str(self.port), self.proto,
            str(self.open_prev), str(self.closed_prev),
            self.dns)


class ScanState(object):
    KEEP_SCANS = 7

    def __init__(self):
        self._lastscan = None
        self._scanlist = []
        self._alerts_open = []
        self._alerts_closed = []
        self._outfile = None

    def up_trend(self):
        ret = ''
        for i in self._scanlist:
            if len(ret) == 0:
                ret = '%d' % len(i.uphosts)
            else:
                ret += ',%d' % len(i.uphosts)
        return ret

    def down_trend(self):
        ret = ''
        for i in self._scanlist:
            if len(ret) == 0:
                ret = '%d' % len(i.downhosts)
            else:
                ret += ',%d' % len(i.downhosts)
        return ret

    def register_outfile(self, o):
        self._outfile = o

    def clear_outfile(self):
        self._outfile = None

    def clear_alerts(self):
        self._alerts_open = []
        self._alerts_closed = []

    def last_scan_total_services(self):
        return self._lastscan.total_services()

    def previous_scan_total_services(self):
        if len(self._scanlist) > 1:
            return self._scanlist[1].total_services()
        return 0

    def set_last(self, last):
        self._lastscan = last
        if len(self._scanlist) == self.KEEP_SCANS:
            self._scanlist.pop()
        self._scanlist.insert(0, last)
        self.clear_alerts()

    def calculate(self):
        self.calculate_new_open()
        self.calculate_new_closed()

    def prev_service_status(self, addr, port, proto):
        openprev = 0
        closedprev = 0
        if len(self._scanlist) <= 1:
            return (0, 0)
        for s in self._scanlist[1:]:
            if s.open_exists(addr, port, proto):
                openprev += 1
            else:
                closedprev += 1
        return (openprev, closedprev)

    def calculate_new_open(self):
        if len(self._scanlist) <= 1:
            return
        for i in self._lastscan.get_hosts():
            for p in self._lastscan.get_host_ports(i):
                prevscan = self._scanlist[1]
                if not prevscan.open_exists(i, p[0], p[1]):
                    statstr = 'OPEN'
                    dns = self._lastscan.dnsmap[i]
                    # If this host isn't in the previous up or down list,
                    # note it as a new host
                    if (i not in prevscan.uphosts) and \
                       (i not in prevscan.downhosts):
                        statstr = 'OPENNEWHOST'
                    openprev, closedprev = \
                        self.prev_service_status(i, p[0], p[1])
                    self._alerts_open.append(Alert(
                        i, p[0], p[1], dns, openprev, closedprev, statstr))

    def calculate_new_closed(self):
        if len(self._scanlist) <= 1:
            return
        prevscan = self._scanlist[1]
        for i in prevscan.get_hosts():
            for p in prevscan.get_host_ports(i):
                if not self._lastscan.open_exists(i, p[0], p[1]):
                    statstr = 'CLOSED'
                    # See if the host existed in the current scan, if it did
                    # use that hostname, otherwise grab previous
                    if i in self._lastscan.dnsmap:
                        dns = self._lastscan.dnsmap[i]
                    else:
                        # If we didn't have a dns map entry for it, that means
                        # the host wasn't even up, note this in the status
                        statstr = 'CLOSEDDOWN'
                        dns = prevscan.dnsmap[i]
                    openprev, closedprev = \
                        self.prev_service_status(i, p[0], p[1])
                    self._alerts_closed.append(Alert(
                        i, p[0], p[1], dns, openprev, closedprev, statstr))

    def print_open_alerts(self):
        self._outfile.write('%s\n' % Alert.alert_header())
        for i in self._alerts_open:
            self._outfile.write('%s\n' % str(i))

    def print_closed_alerts(self):
        self._outfile.write('%s\n' % Alert.alert_header())
        for i in self._alerts_closed:
            self._outfile.write('%s\n' % str(i))

    def outstanding_alerts(self):
        if self._alerts_open or self._alerts_closed:
            return True
        return False


lockfile = None
state = None
tmpfile = None
debugging = False
myhost = None
recip = None
groupname = None
topports = 2000
portspec = None
nosmtp = False
quiet = False

statefile = './diffscan.state'
outdir = './diffscan_out'


def outdir_setup():
    if not os.path.isdir(outdir):
        os.mkdir(outdir, 0o755)
    if not os.access(outdir, os.W_OK):
        sys.stderr.write('%s not writable\n' % outdir)
        sys.exit(1)


def copy_nmap_out(p):
    tval = int(calendar.timegm(time.gmtime()))
    pidval = os.getpid()
    fname = os.path.join(outdir, 'nmap-%d-%d.out' % (tval, pidval))
    shutil.copyfile(p, fname)


def load_scanstate():
    try:
        f = open(statefile, 'r')
    except IOError as e:
        if e.errno == errno.ENOENT:
            return ScanState()
        else:
            raise
    ret = cPickle.load(f)
    f.close()
    return ret


def write_scanstate():
    f = open(statefile, 'w')
    cPickle.dump(state, f)
    f.close()


def parse_output(path):
    new = ScanData()

    f = open(path, 'r')
    while True:
        buf = f.readline()
        if buf is None:
            break
        if buf == '':
            break
        buf = buf.strip()
        m = re.search(r'Host: (\S+) \(([^)]*)\).*Status: Up', buf)
        if m is not None:
            addr = m.group(1)
            new.uphosts.append(addr)
        m = re.search(r'Host: (\S+) \(([^)]*)\).*Status: Down', buf)
        if m is not None:
            addr = m.group(1)
            new.downhosts.append(addr)
        m = re.search(r'Host: (\S+) \(([^)]*)\).*Ports: (.*)$', buf)
        if m is not None:
            addr = m.group(1)
            hn = m.group(2)
            if len(hn) == 0:
                hn = 'unknown'
            p = [x.split('/') for x in m.group(3).split(',')]
            for i in p:
                if i[1] != 'open':
                    continue
                new.add_open(addr.strip(), i[0].strip(), i[2].strip(), hn)
    f.close()

    state.set_last(new)


def diffscan_fail_notify(errmsg):
    if nosmtp:
        return
    buf = 'Subject: diffscan2 %s %s\n' % (groupname, myhost)
    buf += 'From: diffscan2 <noreply@%s>\n' % myhost
    buf += 'To: %s\n' % ','.join(recip)
    buf += '\n'
    buf += 'diffscan execution failed\n\n'
    buf += '%s\n' % errmsg
    sp = subprocess.Popen(['sendmail', '-t'], stdin=subprocess.PIPE)
    sp.communicate(buf)


def run_nmap(targets):
    nmap_args = []
    nmap_args += nmap_scanoptions.split()

    tf = tempfile.mkstemp()
    os.close(tf[0])
    if portspec is not None:
        nmap_args += nmap_portspec.substitute(portspec=portspec).split()
    else:
        nmap_args += nmap_topports.substitute(topports=topports).split()
    nmap_args += nmap_logoptions.substitute(tmppath=tf[1]).split()
    nmap_args += nmap_inoptions.substitute(inpath=targets).split()

    nfd = open('/dev/null', 'w')
    try:
        ret = subprocess.call(['nmap', ] + nmap_args, stdout=nfd)
    except Exception as e:
        os.remove(tf[1])
        diffscan_fail_notify('executing of nmap failed, %s' % str(e))
        return False
    nfd.close()

    if ret != 0:
        os.remove(tf[1])
        diffscan_fail_notify('nmap failed with return code %d, exiting' % ret)
        return False

    parse_output(tf[1])

    copy_nmap_out(tf[1])
    os.remove(tf[1])
    return True


def usage():
    sys.stdout.write(
        'usage: diffscan.py [options] targets_file'
        ' recipients groupname\n\n'
        'options:\n\n'
        '\t-h\t\tusage information\n'
        '\t-m num\t\ttop ports to scan (2000, see nmap --top-ports)\n'
        '\t-n\t\tno smtp, write output to stdout (recipient ignored)\n'
        '\t-o path\t\tdirectory to save nmap output (./diffscan_out)\n'
        '\t-p spec\t\tinstead of top ports use port spec (see nmap -p)\n'
        '\t-s path\t\tpath to state file (./diffscan.state)\n'
        '\t-q\t\tDon\'t send email if no changes \n\n')
    sys.exit(0)


def create_lock():
    global lockfile

    lfname = statefile + '.lock'
    lockfile = open(lfname, 'w')
    fcntl.lockf(lockfile, fcntl.LOCK_EX | fcntl.LOCK_NB)
    lockfile.write(str(os.getpid()))
    lockfile.flush()


def release_lock():
    lfname = statefile + '.lock'

    lockfile.close()
    os.remove(lfname)


def domain():
    global statefile
    global state
    global outdir
    global tmpfile
    global debugging
    global myhost
    global recip
    global groupname
    global topports
    global portspec
    global nosmtp
    global quiet

    os.environ['PATH'] = os.environ['PATH'] + append_path

    try:
        opts, args = getopt.getopt(sys.argv[1:], 'dhm:no:p:s:q')
    except getopt.GetoptError:
        usage()
    for o, a in opts:
        if o == '-h':
            usage()
        elif o == '-o':
            outdir = a
        elif o == '-p':
            portspec = a
        elif o == '-d':
            debugging = True
        elif o == '-m':
            topports = a
        elif o == '-n':
            nosmtp = True
        elif o == '-s':
            statefile = a
        elif o == '-q':
            quiet = True
    if len(args) < 3:
        usage()
    targetfile = args[0]
    recip = args[1].split(',')
    groupname = args[2]

    outdir_setup()

    create_lock()

    state = load_scanstate()

    if not nosmtp:
        tmpout = tempfile.mkstemp()
        tmpfile = os.fdopen(tmpout[0], 'w')
    else:
        tmpfile = sys.stdout
    state.register_outfile(tmpfile)

    myhost = os.uname()[1]
    tmpfile.write('Subject: diffscan2 %s %s\n' % (groupname, myhost))
    tmpfile.write('From: diffscan2 <noreply@%s>\n' % myhost)
    tmpfile.write('To: %s\n' % ','.join(recip))
    tmpfile.write('\n')

    tmpfile.write('diffscan2 results output\n\n')

    if not run_nmap(targetfile):
        if not nosmtp:
            tmpfile.close()
            os.remove(tmpout[1])
        sys.exit(1)
    state.calculate()
    tmpfile.write('New Open Service List\n')
    tmpfile.write('---------------------\n')
    state.print_open_alerts()
    tmpfile.write('\n')
    tmpfile.write('New Closed Service List\n')
    tmpfile.write('---------------------\n')
    state.print_closed_alerts()

    tmpfile.write('\n')
    tmpfile.write('OPREV: number of times service was open in previous scans\n')
    tmpfile.write('CPREV: number of times service was closed in previous scans\n')
    tmpfile.write('maximum previous scans stored: %d\n' % state.KEEP_SCANS)
    tmpfile.write('current total services: %d\n' % state.last_scan_total_services())
    tmpfile.write('previous total services: %d\n' % state.previous_scan_total_services())
    tmpfile.write('up trend: %s\n' % state.up_trend())
    tmpfile.write('down trend: %s\n' % state.down_trend())

    state.clear_outfile()
    write_scanstate()

    if not nosmtp:
        tmpfile.close()

        f = open(tmpout[1], 'r')
        buf = f.read()
        f.close()
        if debugging:
            sys.stdout.write(buf)
        if not (quiet and not state.outstanding_alerts()):
            sp = subprocess.Popen(['sendmail', '-t'], stdin=subprocess.PIPE)
            sp.communicate(buf)
        os.remove(tmpout[1])

    release_lock()


if __name__ == '__main__':
    domain()

sys.exit(0)
