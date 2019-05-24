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
import logging
import time
import yaml

import mwopenstackclients
import requests


logger = logging.getLogger(__name__)


def find_zone_for_fqdn(client, fqdn):
    """Find the correct zone to place a fqdn's record in.

    Searches for the longest existing zone that the record could be placed in.
    """
    parts = fqdn.split('.')
    host = parts.pop(0)  # noqa: F841 local variable never used
    for i in range(len(parts)):
        domain = '.'.join(parts[i:])
        if domain:
            r = client.zones(name=domain)
            if r:
                return r[0]
    return False


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
        '--envfile', default='/etc/novaadmin.yaml',
        help='Path to OpenStack authentication YAML file')
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
    logging.getLogger('iso8601.iso8601').setLevel(logging.WARNING)

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
                'Unknown shard "{}". Expected one of:\n\t- {}'.format(
                    args.shard, '\n\t- '.join(all_shards)))
        shards = [args.shard]
    else:
        shards = all_shards

    dns = mwopenstackclients.DnsManager(
        mwopenstackclients.Clients(envfile=args.envfile), 'noauth-project')
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
                    'https://noc.wikimedia.org/conf/dblists/{}.dblist'.format(svc))
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

            if fqdn in config['cnames']:
                # Add additional aliases for this fqdn
                for cname in config['cnames'][fqdn]:
                    zone = find_zone_for_fqdn(dns, cname)
                    if zone:
                        dns.ensure_recordset(
                            zone['id'], cname, 'CNAME', [fqdn])
                    else:
                        logger.warning('Failed to find zone for %s', cname)


if __name__ == '__main__':
    main()
