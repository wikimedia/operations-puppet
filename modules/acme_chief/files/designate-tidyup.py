#!/usr/bin/python3
from datetime import datetime, timedelta
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

# This type of script is unnecessary for gdnsd which doesn't really have much
# of an API, it just has a command to add records specifically for ACME.
# However, when we add such records to designate in designate-sync.py it
# expects them to be permanent - they're not, so this script cleans them up
# after an hour.
for zone in client.zones.list():
    for recordset in client.recordsets.list(zone['id']):
        if recordset['name'].startswith('_acme-challenge.') and recordset['type'] == 'TXT':
            updated = datetime.fromisoformat(recordset['updated_at'] or recordset['created_at'])
            if (datetime.now() - updated) > timedelta(hours=1):
                print("Deleting recordset {} from zone {}, more than an hour old.".format(
                    recordset['name'],
                    zone['name']
                ))
                print("Records being removed: {}".format(recordset['records']))
                client.recordsets.delete(zone['id'], recordset['id'])
