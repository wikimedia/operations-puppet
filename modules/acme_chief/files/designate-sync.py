#!/usr/bin/python3
import argparse
import yaml

from designateclient.v2 import client as designateclient
from keystoneauth1.identity import v3
from keystoneauth1 import session as keystone_session

with open('/etc/acme-chief/designate-sync-config.yaml') as f:
    config = yaml.safe_load(f)

client = designateclient.Client(
    session=keystone_session.Session(auth=v3.Password(
        auth_url=config['OS_AUTH_URL'],
        username=config['OS_USERNAME'],
        password=config['OS_PASSWORD'],
        user_domain_name='default',
        project_domain_name='default',
        project_name=config['OS_PROJECT_NAME']
    )),
    region_name=config['OS_REGION_NAME']
)

parser = argparse.ArgumentParser(description='Sync DNS changes')
parser.add_argument('params', metavar='PARAM', nargs='+',
                    help='Each domain followed by the validation string. '
                         'Number of params must be even.')

# This parameter is not used in this script, but this script is not run by
# humans, it is run by acme-chief which will provide the parameter so we must
# be willing to accept (and ignore) it.
parser.add_argument('--remote-servers', metavar='REMOTE_SERVER', nargs='+',
                    required=True, help='Remote servers to send command to. '
                                        'Unused for Designate support.')
args = parser.parse_args()
print(args.params)
# Go through each pair of parameters - the first one will be a domain and the
# second will be the value of the TXT record to create.
for i in range(0, len(args.params), 2):
    domain, validation_str = args.params[i], args.params[i+1]
    if not domain.startswith('_acme-challenge.'):
        domain = '_acme-challenge.' + domain
    if domain[-1] != '.':
        domain += '.'

    # Find all zones we might want to put this record in
    potential_zones = []
    for zone in client.zones.list():
        if domain.endswith('.' + zone['name']):
            zone['match_specificness'] = len(zone['name'].split('.'))
            potential_zones.append(zone)

    # Pick the most specific zone to put it in
    potential_zones.sort(key=lambda z: z['match_specificness'], reverse=True)
    zone = potential_zones[0]
    # This means c.b.a.wmflabs.org will go under b.a.wmflabs.org rather than
    # a.wmflabs.org.

    # Look for existing records to potentially update
    for recordset in client.recordsets.list(zone['id']):
        if recordset['name'] == domain and recordset['type'] == 'TXT':
            if validation_str not in recordset['records']:
                recordset['records'].append(validation_str)
                client.recordsets.update(
                    zone['id'],
                    recordset['id'],
                    {"records": recordset['records']}
                )
            break
    else:
        # Create it
        client.recordsets.create(zone['id'], domain, 'TXT', [validation_str])
