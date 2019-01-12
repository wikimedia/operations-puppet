#!/usr/bin/python
#
# Copyright (c) 2019 Wikimedia Foundation and contributors
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.
#
# This is probably a one-off script but I'm keeping it around in case it's useful.
#  It enumerages almost all cloud VPS proxies and reassigns their proxy IP.
#
# This script doesn't handle proxies whose DNS entries are owned by a project
#  other than wmflabsdotorg.  For example, in maps there are some projects that
#  are in a maps-owned subdomain.  Those cases are few enough that it seems
#  safer to update them by hand than to make this script handle every corner case.
#
#
from __future__ import print_function

import argparse
import logging
import operator

import mwopenstackclients
import requests


ZONE = 'wmflabs.org.'
TENANT = 'wmflabsdotorg'
logger = logging.getLogger(__name__)


def url_template(client):
    """Get the url template for accessing the proxy service."""
    keystone = client.keystoneclient()
    proxy = keystone.services.list(type='proxy')[0]
    endpoint = keystone.endpoints.list(
        service=proxy.id, interface='public', enabled=True)[0]
    return endpoint.url


def update_proxies(args):
    """List proxies for a tenant."""
    client = mwopenstackclients.Clients(envfile=args.envfile)

    dns = mwopenstackclients.DnsManager(client, tenant=TENANT)

    allprojects = client.allprojects()
    allprojectslist = [project.name for project in allprojects]

    for projectid in allprojectslist:
        print(" ----  project: %s" % projectid)
        base_url = url_template(client).replace('$(tenant_id)s', projectid)

        resp = requests.get('{}/mapping'.format(base_url))
        if resp.status_code != 400:
            data = resp.json()
            for route in sorted(data['routes'], key=operator.itemgetter('domain')):
                z = dns.zones(name=ZONE)[0]  # blow up if zone doesn't exist
                zone_id = z['id']
                fqdn = route['domain']
                if not fqdn.endswith('.'):
                    fqdn += "."
                recordset = dns.recordsets(zone_id, fqdn)
                if not recordset:
                    print("Bad news! Can't find %s in zone %s" % (fqdn, zone_id))
                elif len(recordset) > 1:
                    print("Bad news! Multiple recordsets for %s." % fqdn)
                elif len(recordset[0]['records']) > 1:
                    print("Bad news! Multiple records for %s." % fqdn)
                elif recordset[0]['records'][0] != args.ip:
                    print("Updating recordset %s from %s to %s" %
                          (fqdn, recordset[0]['records'][0], args.ip))
                    if not args.dryrun:
                        dns.ensure_recordset(zone_id, fqdn, 'A', [args.ip])
                else:
                    print("This one (%s) is already good." % fqdn)


def main():
    """Manage proxies for Cloud VPS servers"""
    parser = argparse.ArgumentParser(description='Assign Cloud VPS proxies to a new IP')
    parser.add_argument(
        '-v', '--verbose', action='count',
        default=0, dest='loglevel', help='Increase logging verbosity')
    parser.add_argument(
        '--envfile', default='/etc/novaadmin.yaml',
        help='Path to OpenStack authentication YAML file')
    parser.add_argument(
        '-d', '--dry-run', action='count', default=0,
        dest='dryrun',
        help="Show what you would do but don't do it")
    parser.add_argument(
        'ip', help='IPv4 address of the new nginx proxy host')

    args = parser.parse_args()

    logging.basicConfig(
        level=max(logging.DEBUG, logging.WARNING - (10 * args.loglevel)),
        format='%(asctime)s %(name)-12s %(levelname)-8s: %(message)s',
        datefmt='%Y-%m-%dT%H:%M:%SZ'
    )
    logging.captureWarnings(True)
    # Quiet some noisy 3rd-party loggers channels
    logging.getLogger('requests').setLevel(logging.WARNING)
    logging.getLogger('urllib3').setLevel(logging.WARNING)

    update_proxies(args)


if __name__ == '__main__':
    main()
