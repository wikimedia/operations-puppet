#!/usr/bin/python
"""
"""

import configparser
import argparse

from keystoneclient.auth.identity import generic
from keystoneclient import session as keystone_session
from novaclient import client
from neutronclient.v2_0 import client as neutronclient


class NovaProject(object):

    def __init__(self,
                 project,
                 common_config,
                 source_config,
                 dest_config):

        self.source_config = source_config
        self.dest_config = dest_config
        self.common_config = common_config
        self.project = project

        source_auth = generic.Password(
            auth_url=self.common_config['keystone_url'],
            username=self.common_config['user'],
            password=self.common_config['password'],
            user_domain_name='Default',
            project_domain_name='Default',
            project_name='admin')
        source_session = keystone_session.Session(auth=source_auth)
        self.source_novaclient = client.Client('2', session=source_session,
                                               region_name=source_config['region'])

        dest_auth = generic.Password(
            auth_url=self.common_config['keystone_url'],
            username=self.common_config['user'],
            password=self.common_config['password'],
            user_domain_name='Default',
            project_domain_name='Default',
            project_name='admin')
        self.dest_session = keystone_session.Session(auth=dest_auth)
        self.dest_novaclient = client.Client('2', session=self.dest_session,
                                             region_name=dest_config['region'])
        self.dest_neutronclient = neutronclient.Client(session=self.dest_session,
                                                       region_name=dest_config['region'])

    def copy(self):
        source_quotas = self.source_novaclient.quotas.get(self.project)
        self.dest_novaclient.quotas.update(self.project,
                                           cores=source_quotas.cores,
                                           floating_ips=source_quotas.floating_ips,
                                           instances=source_quotas.instances,
                                           ram=source_quotas.ram)
        self.dest_neutronclient.update_quota(self.project,
                                             {"quota": {"floatingip": source_quotas.floating_ips}})

        print("Updated quotas using %s" % source_quotas)
        return


if __name__ == "__main__":
    config = configparser.ConfigParser()
    config.read('region-migrate.conf')
    if 'source' not in config.sections():
        print("config requires a 'source' section")
        exit(1)
    if 'dest' not in config.sections():
        print("config requires a 'dest' section")
        exit(1)

    argparser = argparse.ArgumentParser('region-migrate-quotas',
                                        description="Copy nova quotas "
                                        "from one region to another")
    argparser.add_argument(
        'project',
        help='project to migrate',
    )
    args = argparser.parse_args()

    project = NovaProject(args.project,
                          config['common'],
                          config['source'],
                          config['dest'])

    project.copy()
