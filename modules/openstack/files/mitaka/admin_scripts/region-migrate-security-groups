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

        source_auth = generic.Password(
            auth_url=self.common_config['keystone_url'],
            username=self.common_config['user'],
            password=self.common_config['password'],
            user_domain_name='Default',
            project_domain_name='Default',
            project_name=project)
        source_session = keystone_session.Session(auth=source_auth)
        self.source_novaclient = client.Client('2', session=source_session,
                                               region_name=source_config['region'])

        dest_auth = generic.Password(
            auth_url=self.common_config['keystone_url'],
            username=self.common_config['user'],
            password=self.common_config['password'],
            user_domain_name='Default',
            project_domain_name='Default',
            project_name=project)
        self.dest_session = keystone_session.Session(auth=dest_auth)
        self.dest_neutronclient = neutronclient.Client(session=self.dest_session,
                                                       region_name=dest_config['region'])

    def copy(self):
        source_groups = self.source_novaclient.security_groups.list()
        dest_groups = self.dest_neutronclient.list_security_groups()['security_groups']
        dest_group_dict = {group["name"]: group for group in dest_groups}
        for source_group in source_groups:
            if source_group.name in dest_group_dict.keys():
                dest_group = dest_group_dict[source_group.name]
                for rule in dest_group['security_group_rules']:
                    if rule['direction'] == 'ingress':
                        # We want to remove any existing Neutron ingress rules, because they're too
                        #  permissive by default.
                        # Egress rules we let alone; nova doesn't even have those.
                        print("deleting rule %s" % rule)
                        self.dest_neutronclient.delete_security_group_rule(rule['id'])
            else:
                print("Creating group %s in dest" % source_group.name)
                dest_group = self.dest_neutronclient.create_security_group(
                    {"security_group":
                     {"name": source_group.name,
                      "description": source_group.description}})
                # save this for later in case a rule wants to refer to it by id
                dest_group_dict[source_group.name] = dest_group

        for source_group in source_groups:
            print("Updating group %s in dest" % source_group.name)

            for rule in source_group.rules:
                print("copying rule: %s" % rule)
                newrule = {'security_group_rule': {
                    'security_group_id': dest_group_dict[source_group.name]['id'],
                    'direction': 'ingress',
                    'ethertype': 'IPv4',
                    'protocol': rule['ip_protocol'],
                    'port_range_min': rule['from_port'],
                    'port_range_max': rule['to_port'],
                    }}

                if rule['from_port'] < 0 and rule['to_port'] < 0:
                    del newrule['security_group_rule']['port_range_min']
                    del newrule['security_group_rule']['port_range_max']

                if 'cidr' in rule['ip_range']:
                    newrule['security_group_rule']['remote_ip_prefix'] = rule['ip_range']['cidr']

                if rule['group']:
                    newrule['security_group_rule']['remote_group_id'] = dest_group_dict[
                            rule['group']['name']]['id']

                self.dest_neutronclient.create_security_group_rule(newrule)

                if 'cidr' in rule['ip_range'] and (
                        rule['ip_range']['cidr'] == '10.0.0.0/8' or
                        rule['ip_range']['cidr'] == '10.4.0.0/16'):
                    # This rule is intended as an 'all VMs catch-all'.  We need to add an
                    #  equivalent rule for the new region.
                    newrule['security_group_rule']['remote_ip_prefix'] = '172.16.0.0/21'
                    self.dest_neutronclient.create_security_group_rule(newrule)


if __name__ == "__main__":
    config = configparser.ConfigParser()
    config.read('region-migrate.conf')
    if 'source' not in config.sections():
        print("config requires a 'source' section")
        exit(1)
    if 'dest' not in config.sections():
        print("config requires a 'dest' section")
        exit(1)

    argparser = argparse.ArgumentParser('region-migrate-security-groups',
                                        description="Copy security groups "
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
