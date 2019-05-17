#!/usr/bin/python
"""
makedomain is a library for creating subdomains of existing designate domains.

Designate forbids creation of a subdomain when the superdomain already exists
as part of a different project.  It does, however, support cross-project
transfers of such domains.

Note that this only works with the keystone v2.0 API.

"""

import time

from keystoneauth1.identity import v3
from keystoneauth1 import session as keystone_session
from designateclient.v2 import client
from oslo_log import log as logging

LOG = logging.getLogger('keystone.%s' % __name__)


def deleteDomain(url, user, password, project, domain="", delete_all=False):
    auth = v3.Password(
        auth_url=url,
        username=user,
        password=password,
        user_domain_name='Default',
        project_domain_name='Default',
        project_id=project)

    targetSession = keystone_session.Session(auth=auth)
    targetClient = client.Client(session=targetSession, region_name='eqiad1-r')

    domains = targetClient.zones.list()
    for thisdomain in domains:
        if delete_all:
            LOG.info("Deleting %s" % thisdomain['name'])
            targetClient.zones.delete(thisdomain['id'])
        else:
            if thisdomain['name'] == domain:
                targetClient.zones.delete(thisdomain['id'])
                return
    if not delete_all:
        LOG.warning("Domain %s not found" % domain)


def createDomain(url, user, password, project, domain, ttl=120):
    auth = v3.Password(
        auth_url=url,
        username=user,
        password=password,
        user_domain_name='Default',
        project_domain_name='Default',
        project_id='wmflabsdotorg')

    createSession = keystone_session.Session(auth=auth)
    createClient = client.Client(session=createSession, region_name='eqiad1-r')

    auth = v3.Password(
        auth_url=url,
        username=user,
        password=password,
        user_domain_name='Default',
        project_domain_name='Default',
        project_id=project)

    targetSession = keystone_session.Session(auth=auth)

    # Fixme:  Once we move to a more modern version of designateclient (newton?)
    #  we should pass sudo-project-id=wmflabsdotorg here, change createSession
    #  to use the 'admin' project, and remove novaadmin's 'admin' role from wmflabsdotorg.
    targetClient = client.Client(session=targetSession, region_name='eqiad1-r')

    # Create the zone in the initial wmflabsdotorg project.  This
    #  is needed since wmflabs.org lives in that project and
    #  designate prevents subdomain creation elsewhere.
    LOG.info("Creating %s" % domain)
    zone = createClient.zones.create(domain, email='root@wmflabs.org', ttl=ttl)
    status = 'PENDING'
    # Wait for the domain to actually exist before we transfer it
    while status == 'PENDING':
        zone = createClient.zones.get(domain)
        status = zone['status']
        time.sleep(2)

    transferRequest = createClient.zone_transfers.create_request(domain, project)
    transferId = transferRequest['id']
    transferKey = transferRequest['key']

    targetClient.zone_transfers.accept_request(transferId, transferKey)
