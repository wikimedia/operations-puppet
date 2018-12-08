#!/usr/bin/python
#
# Copyright (c) 2018 Wikimedia Foundation and contributors
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
from __future__ import print_function

import argparse
import json
import logging
import operator
import socket
import urlparse

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


def add_proxy(args):
    """Setup DNS and dynamicproxy mapping from a host to a URL."""
    client = mwopenstackclients.Clients(envfile=args.envfile)
    base_url = url_template(client).replace('$(tenant_id)s', args.project)

    dns = mwopenstackclients.DnsManager(client, tenant=TENANT)
    proxyip = socket.gethostbyname(urlparse.urlparse(base_url).hostname)
    z = dns.zones(name=ZONE)[0]  # blow up if zone doesn't exist
    zone_id = z['id']
    fqdn = '{}.{}'.format(args.host, ZONE)
    dns.ensure_recordset(zone_id, fqdn, 'A', [proxyip])

    resp = requests.put(
        '{}/mapping'.format(base_url),
        data=json.dumps({
            'backends': [args.target_url],
            'domain': fqdn.rstrip('.')
        }))
    if not resp:
        raise Exception(
            'HTTP {} response from dynamicproxy: {}'.format(
                resp.status_code, resp.text))


def list_proxies(args):
    """List proxies for a tenant."""
    client = mwopenstackclients.Clients(envfile=args.envfile)
    base_url = url_template(client).replace('$(tenant_id)s', args.project)

    resp = requests.get('{}/mapping'.format(base_url))
    if resp.status_code == 400 and resp.text == 'No such project':
        raise Exception('Unknown project {}'.format(args.project))
    data = resp.json()
    row = "{:<48} {}"
    print(row.format('domain', 'backend'))
    print(row.format('='*48, '='*24))
    for route in sorted(data['routes'], key=operator.itemgetter('domain')):
        print(row.format(route['domain'], route['backends'][0]))


def delete_proxy(args):
    """Delete a proxy."""
    client = mwopenstackclients.Clients(envfile=args.envfile)
    base_url = url_template(client).replace('$(tenant_id)s', args.project)

    dns = mwopenstackclients.DnsManager(client, tenant=TENANT)
    z = dns.zones(name=ZONE)[0]  # blow up if zone doesn't exist
    zone_id = z['id']
    fqdn = '{}.{}'.format(args.host, ZONE)

    # Remove proxy
    resp = requests.delete('{}/mapping/{}'.format(base_url, fqdn.rstrip('.')))
    if resp:
        # Remove DNS
        rs = dns.recordsets(zone_id, name=fqdn)[0]
        dns.delete_recordset(zone_id, rs['id'])
    else:
        raise Exception(
            'HTTP {} response from dynamicproxy: {}'.format(
                resp.status_code, resp.text))


def main():
    """Manage proxies for Cloud VPS servers"""
    parser = argparse.ArgumentParser(description='Cloud VPS proxy manager')
    parser.add_argument(
        '-v', '--verbose', action='count',
        default=0, dest='loglevel', help='Increase logging verbosity')
    parser.add_argument(
        '--envfile', default='/etc/novaadmin.yaml',
        help='Path to OpenStack authentication YAML file')
    parser.add_argument(
        '-p', '--project', required=True,
        help='Cloud VPS project that owns proxy')
    subparsers = parser.add_subparsers(
        title='subcommands', description='valid subcommands',
        help='additional help')

    parser_list = subparsers.add_parser('list', help='List proxies')
    parser_list.set_defaults(func=list_proxies)

    parser_add = subparsers.add_parser('add', help='Add a new proxy')
    parser_add.add_argument(
        'host', help='Proxy hostname (under wmflabs.org domain)')
    parser_add.add_argument(
        'target_url', help='URL to proxy to')
    parser_add.set_defaults(func=add_proxy)

    parser_delete = subparsers.add_parser('delete', help='Delete a proxy')
    parser_delete.add_argument(
        'host', help='Proxy hostname (under wmflabs.org domain)')
    parser_delete.set_defaults(func=delete_proxy)

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

    args.func(args)


if __name__ == '__main__':
    main()
