#!/usr/bin/python
#
# Copyright (c) 2017 Wikimedia Foundation and contributors
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
import time
import yaml

import mwopenstackclients
import requests


logger = logging.getLogger(__name__)


class DnsManager(object):
    """Wrapper for communicating with Designate API."""
    def __init__(self):
        clients = mwopenstackclients.clients()
        services = clients.keystoneclient().services.list()
        serviceid = [s.id for s in services if s.type == 'dns'][0]
        endpoints = clients.keystoneclient().endpoints.list(serviceid)
        self.url = [e.url for e in endpoints if e.interface == 'public'][0]
        session = clients.session()
        self.token = session.get_token()

    def _json_http_kwargs(self, kwargs):
        kwargs['headers'] = {
            'Content-type': 'application/json',
        }
        if 'data' in kwargs:
            kwargs['data'] = json.dumps(kwargs['data'])
        return kwargs

    def _req(self, verb, *args, **kwargs):
        # Work around lack of X-Auth-Sudo-Tenant-ID support in
        # python-designateclient <2.2.0 with direct use of API.
        map = {
            'GET': requests.get,
            'POST': requests.post,
            'PUT': requests.put,
            'PATCH': requests.patch,
            'DELETE': requests.delete,
        }
        args = list(args)
        args[0] = self.url + args[0]
        headers = kwargs.get('headers', {})
        headers.update({
            'X-Auth-Token': self.token,
            'X-Auth-Sudo-Tenant-ID': 'noauth-project',
            'X-Designate-Edit-Managed-Records': 'true',
        })
        kwargs['headers'] = headers
        r = map[verb.upper()](*args, **kwargs)
        if r.status_code >= 400:
            logging.warning('Error response from %s:\n%s', args[0], r.text)
        r.raise_for_status()
        return r

    def _get(self, *args, **kwargs):
        return self._req('GET', *args, **kwargs)

    def _post(self, *args, **kwargs):
        kwargs = self._json_http_kwargs(kwargs)
        return self._req('POST', *args, **kwargs)

    def _put(self, *args, **kwargs):
        kwargs = self._json_http_kwargs(kwargs)
        return self._req('PUT', *args, **kwargs)

    def zones(self, name=None, params=None):
        params = params or {}
        if name:
            params['name'] = name
        r = self._get('/v2/zones', params=params)
        return r.json()['zones']

    def create_zone(
        self, name, type_="primary", email=None, description=None,
        ttl=None, masters=None, attributes=None
    ):
        data = {
            "name": name,
            "type": type_,
        }
        if type_ == "primary":
            if email:
                data["email"] = email
            if ttl is not None:
                data["ttl"] = ttl
        elif type_ == "secondary" and masters:
            data["masters"] = masters

        if description is not None:
            data["description"] = description

        if attributes is not None:
            data["attributes"] = attributes
        r = self._post('/v2/zones', data=data)
        return r.json()

    def ensure_zone(
        self, name, type_="primary", email=None, description=None,
        ttl=None, masters=None, attributes=None
    ):
        """Ensure that a zone exists."""
        r = self.zones(name=name)
        if not r:
            logger.warning('Creating zone %s', name)
            z = self.create_zone(name, email='root@wmflabs.org', ttl=60)
        else:
            z = r[0]
        return z

    def recordsets(self, uuid, name=None, params=None):
        params = params or {}
        if name:
            params['name'] = name
        r = self._get('/v2/zones/{}/recordsets'.format(uuid), params=params)
        return r.json()['recordsets']

    def create_recordset(
        self, uuid, name, type_, records, description=None, ttl=None
    ):
        data = {
            "name": name,
            "type": type_,
            "records": records,
        }
        if description is not None:
            data["description"] = description
        if ttl is not None:
            data["ttl"] = ttl
        r = self._post('/v2/zones/{}/recordsets'.format(uuid), data=data)
        return r.json()

    def update_recordset(
        self, uuid, rs, records, description=None, ttl=None
    ):
        data = {
            "records": records,
        }
        if description is not None:
            data["description"] = description
        if ttl is not None:
            data["ttl"] = ttl
        r = self._put('/v2/zones/{}/recordsets/{}'.format(uuid, rs), data=data)
        return r.json()

    def ensure_recordset(
        self, zone, name, type_, records, description=None, ttl=None
    ):
        """Find or create a recordest and make sure it matches the given
        records."""
        r = self.recordsets(zone, name=name)
        if not r:
            logger.warning('Creating %s', name)
            rs = self.create_recordset(zone, name, type_, records)
        else:
            rs = r[0]
        if rs['records'] != records:
            logger.info('Updating %s', name)
            rs = self.update_recordset(zone, rs['id'], records)


def main():
    """Manage Designate DNS records for Wiki Replicas."""
    parser = argparse.ArgumentParser(description='Wiki Replica DNS Manager')
    parser.add_argument(
        '-v', '--verbose', action='count', default=0, dest='loglevel',
        help='Increase logging verbosity')
    parser.add_argument(
        '--config', default='/etc/wikireplica_dns.yaml',
        help='Path to YAML config file')
    parser.add_argument(
        '--zone',
        help='limit changes to the given zone')
    parser.add_argument(
        '--aliases', action='store_true',
        help='Update per-wiki CNAME records')
    parser.add_argument(
        '--shard',
        help='limit changes to the given shard')
    args = parser.parse_args()

    logging.basicConfig(
        level=max(logging.DEBUG, logging.WARNING - (10 * args.loglevel)),
        format='%(asctime)s %(name)-12s %(levelname)-8s: %(message)s',
        datefmt='%Y-%m-%dT%H:%M:%SZ'
    )
    logging.captureWarnings(True)
    # Quiet some noisy 3rd-party loggers
    logging.getLogger('requests').setLevel(logging.WARNING)
    logging.getLogger('urllib3').setLevel(logging.WARNING)

    with open(args.config) as f:
        config = yaml.safe_load(f)

    all_zones = [z for z in config['zones']]
    if args.zone:
        if args.zone not in all_zones:
            parser.error(
                'Unknown zone "{}". Expected one of:\n\t- {}'.format(
                    args.zone, '\n\t- '.join(all_zones)))
        zones = [args.zone]
    else:
        zones = all_zones

    all_shards = ['s1', 's2', 's3', 's4', 's5', 's6', 's7', 's8']
    if args.shard:
        if args.shard not in all_shards:
            parser.error(
                'Unknown shard "{}}. Expected one of:\n\t- {}'.format(
                    args.shard, '\n\t- '.join(all_shards)))
        shards = [args.shard]
    else:
        shards = all_shards

    dns = DnsManager()
    for zone in zones:
        r = dns.zones(name=zone)
        if not r:
            logger.warning('Creating zone %s', zone)
            z = dns.create_zone(zone, email='root@wmflabs.org', ttl=60)
        else:
            z = r[0]
        zone_id = z['id']

        for svc, ips in config['zones'][zone].iteritems():
            # Goofy, but true -- Designate needs FQDNs for names.
            fqdn = '{}.{}'.format(svc, zone)
            dns.ensure_recordset(zone_id, fqdn, 'A', ips)

            if args.aliases and svc in shards:
                # Ensure that there are wikidb aliases for shards
                dblist = requests.get(
                    'https://noc.wikimedia.org/conf/{}.dblist'.format(svc))
                try:
                    dblist.raise_for_status()
                except requests.exceptions.HTTPError:
                    logger.warning('DBList "%s" not found', svc)
                else:
                    for wikidb in dblist.text.splitlines():
                        db_fqdn = '{}.{}'.format(wikidb, zone)
                        dns.ensure_recordset(zone_id, db_fqdn, 'CNAME', [fqdn])
                        # Take a small break to be nicer to Designate
                        time.sleep(0.25)

                if svc in config['cnames']:
                    # Add additional aliases for this shard
                    for host in config['cnames'][svc]:
                        db_fqdn = '{}.{}'.format(host, zone)
                        dns.ensure_recordset(
                            zone_id, db_fqdn, 'CNAME', [fqdn])


if __name__ == '__main__':
    main()
