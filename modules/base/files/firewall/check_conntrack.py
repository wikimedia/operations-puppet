#!/usr/bin/python
import string


def _get_sysctl(self, name):

    path = '/proc/sys/' + name.translate(string.maketrans('.', '/'))

    try:
        with open(path) as f:
            value = f.read().rstrip('\n')
        return value

    except IOError:
        return None


def collect(self):

    max_value = self._get_sysctl('net.netfilter.nf_conntrack_max')
    if max_value is not None and max_value > 0:
        count_value = self._get_sysctl('net.netfilter.nf_conntrack_count')
        full = count_value/max_value*100
    if int(full) >= 80 and <= 90:
        print "Warning: nf_conntrack is %s % full" % (full)
        sys.exit(1)
    elif int(full) >= 90:
        print "Critical: nf_conntrack is %s % full" % (full)
        sys.exit(2)
    elif int(full) < 80:
        print "OK: nf_conntrack is %s % full" % (full)
        sys.exit(0)
    else:
        print "UNKNOWN: error reading nf_conntrack"
        sys.exit(3)
