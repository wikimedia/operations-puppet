#!/usr/bin/env python
#
# this script returns the server-id of the current master
# cluster name must be in /etc/db.cluster, set by puppet
# and $cluster-master should be an up-to-date CNAME to
# the master.
#

from socket import gethostbyname
masterdom = '.pmtpa.wmnet'

f = open('/etc/db.cluster', 'r')
c = f.readline()
mip = gethostbyname(c.split()[0] + '-master' + masterdom)
octets = mip.split('.')
print octets[0] + octets[2] + octets[3]
