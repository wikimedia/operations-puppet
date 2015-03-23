#!/usr/bin/python

#####################################################################
### THIS FILE IS MANAGED BY PUPPET
### puppet:///modules/ldap/scripts/puppetsigner.py
#####################################################################

import sys
import re
import ldapsupportlib
import subprocess
import os
import json
import ldap
from optparse import OptionParser  # FIXME: Use argparse


def getPuppetInfo(attr, conffile="/etc/puppet/puppet.conf"):
    f = open(conffile)
    for line in f:
        if line.split('=', 1)[0].strip() == attr:
            return line.split('=', 1)[1].strip()


parser = OptionParser(conflict_handler="resolve")
parser.set_usage("puppetsigner [options]")
ldapSupportLib = ldapsupportlib.LDAPSupportLib()
ldapSupportLib.addParserOptions(parser)
(options, args) = parser.parse_args()

ldapSupportLib.setBindInfoByOptions(options, parser)
ds = ldapSupportLib.connect()
basedn = ldapSupportLib.getLdapInfo('base')

try:
    puppet_output = subprocess.check_output(['/usr/bin/puppet', 'cert', 'list'])
    hosts = puppet_output.split()
    for host in hosts:
        # check to make sure hostname is actual hostname, to prevent
        # ldap injection attacks
        if host[0] == "(":
            continue  # FIXME: WAT
        host = host.strip('"')  # FIXME: WAT
        if not re.match(r'^[a-zA-Z0-9_-]+\.eqiad\.wmflabs$', host):
            print 'Invalid hostname', host
            sys.exit(-1)
        query = "(&(objectclass=puppetclient)(|(dc=" + host + ")(cnamerecord=" + host + ")(associateddomain=" + host + ")))"
        host_info = ds.search_s(basedn, ldap.SCOPE_SUBTREE, query)
        if not host_info:
            path = getPuppetInfo('ssldir') + '/ca/requests/' + host + '.pem'
            try:
                os.remove(path)
            except Exception:
                # FIXME: WAT
                sys.stderr.write('Failed to remove the certificate: ' + path + '\n')
        else:
            subprocess.check_call(['/usr/bin/puppet', 'cert', 'sign', host])
            subprocess.check_call(['/usr/bin/php',
                                   '/srv/org/wikimedia/controller/wikis/w/extensions/OpenStackManager/maintenance/onInstanceActionCompletion.php',
                                   '--action', 'build',
                                   '--instance', host])
    salt_output = subprocess.check_output(['/usr/bin/salt-key',
                                           '--list', 'unaccepted',
                                           '--out', 'json'])
    hosts = json.loads(salt_output)
    for host in hosts["minions_pre"]:
        if not re.match(r'^[a-zA-Z0-9_-]+\.eqiad\.wmflabs$', host):
            print 'Invalid hostname', host
            sys.exit(-1)
        query = "(&(objectclass=puppetclient)(|(dc=" + host + ")(cnamerecord=" + host + ")(associateddomain=" + host + ")))"
        host_result = ds.search_s(basedn, ldap.SCOPE_SUBTREE, query)
        if not host_result:
            subprocess.check_call(['/usr/bin/salt-key', '-y', '-d', host])
        else:
            subprocess.check_call(['/usr/bin/salt-key', '-y', '-a', host])
finally:
    ds.unbind()
