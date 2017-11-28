#!/usr/bin/python

import sys

import mwopenstackclients


certname = sys.argv[1]
clients = mwopenstackclients.clients(envfile='/etc/novaobserver.yaml')

pieces = certname.split('.')
if len(pieces) != 4:
    sys.exit('certname %s is formatted incorrectly' % certname)

if pieces[2] != 'eqiad':
    sys.exit('certname %s is for an invalid site' % certname)

if pieces[3] != 'wmflabs':
    sys.exit('certname %s does not end with wmflabs' % certname)

certhostname = pieces[0]
certproject = pieces[1]

projects = [project.id for project in clients.allprojects()]
if certproject not in projects:
    sys.exit('certname %s is not for a real project' % certname)

# the cert name will always be lowercase.  So we need to lower()
#  the instance name for proper comparison
instances = [instance.name.lower()
             for instance in clients.novaclient(certproject).servers.list()]
if certhostname not in instances:
    sys.exit('certname %s is not for a real instance' % certname)

sys.exit(0)
