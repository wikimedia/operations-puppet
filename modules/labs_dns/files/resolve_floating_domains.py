#!/usr/bin/python
import fnmatch
import sys
import syslog
import os


def parse(fd, out, hosts):
    line = fd.readline().strip()
    if not line.startswith('HELO'):
        print >>out, 'FAIL'
        out.flush()
        syslog.syslog('received "%s", expected "HELO"' % (line,))
        sys.exit(1)
    else:
        print >>out, 'OK\t%s ready' % (os.path.basename(sys.argv[0]),)
        out.flush()
        syslog.syslog('received HELO from PowerDNS')

    while True:
        syslog.syslog('Reading')
        line = fd.readline().strip()
        if not line:
            syslog.syslog('Pipe backend closing')
            break
        syslog.syslog('Pipe backend read a line')

        request = line.split('\t')
        if request[0] == 'AXFR':
            continue

        if len(request) < 6:
            print >>out, 'LOG\tPowerDNS sent unparsable line'
            print >>out, 'FAIL'
            out.flush()
            continue

        try:
            kind, qname, qclass, qtype, qid, ip = request
        except:
            kind, qname, qclass, qtype, qid, ip, their_ip = request

        qname = qname.lower()

        if qtype in ['A', 'ANY'] and qname.endswith('wmflabs.org'):
            print >>out, 'LOG\tfloating_domain_backend got query: %s' % qtype
            matchname = qname
            for key in hosts.keys():
                if fnmatch(matchname, key):
                    host = hosts[key]
                    print >>out, ('DATA\t%s\t%s\tA\t%d\t-1\t%s' %
                                  (qname, qclass, host['ttl'], host['ip']))
                    break

        print >>out, 'END'
        out.flush()


def loadhosts(filename):
    hosts = {}

    with open(filename) as fp:
        for line in fp:
            if line[0] == '#':
                continue

            host = {}

            pieces = line.split()
            if len(pieces) == 0:
                continue
            if len(pieces) != 2:
                syslog.syslog("Bad host entry: %s" % line)
                continue

            host['ip'] = pieces[1]
            host['ttl'] = 300
            name = pieces[0]
            hosts['name'] = host

    return hosts


if __name__ == '__main__':
    import sys
    syslog.syslog('Pipe backend loading domains')
    hosts = loadhosts("/etc/powerdns/floating_domains")
    syslog.syslog('Pipe backend loaded domains')
    sys.exit(parse(sys.stdin, sys.stdout, hosts))
