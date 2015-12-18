#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
  new_service -- shell helper for automating introduction of a new service

  Usage: ./new_service.py

  Requirements: Running it from the utils/ directory
  # TODO: Make it runnable from anywhere
  # TODO: Use jinja for templating

  Copyright 2015 Alexandros Kosiaris <akosiaris@wikimedia.org>
  Licensed under the Apache license.
"""

import re
import os
import argparse
import yaml
import copy
from subprocess import call
from collections import OrderedDict

QUESTIONS = [
    {
        'qname': 'service_name',
        'qstring': 'What will be the name of the service',
        'validator': lambda x: True if re.match('^[a-z_]{6,20}$', x) else False,
        'transformer': lambda x: x,
    },
    {
        'qname': 'service_description',
        'qstring': 'A one line description of the service',
        'validator': lambda x: True if re.match('^[\w\s,\.-]+$', x) else False,
        'transformer': lambda x: x,
    },
    {
        'qname': 'service_node',
        'qstring': 'Does it adhere to the service::node paradigm (Y/n)',
        'validator': lambda x: True if re.match('^[Yy]([Ee][Ss])?|[Nn]([Oo])?|$', x) else False,
        'transformer': lambda x: True if re.match('^[Yy]([Ee][Ss])?|$', x) else False,
    },
    {
        'qname': 'port',
        'qstring': 'Which TCP port does it listen on?',
        'validator': lambda x: True if re.match('^[0-9]{4,5}$', x) else False,
        'transformer': lambda x: x,
        # TODO: Make the validator stricter and perhaps get a list of already
        # occupied ports from lvs::configuration::services
    },
    {
        'qname': 'cluster',
        'qstring': 'Which cluster will serve it',
        'validator': lambda x: True if re.match('^[a-z]{3,20}$', x) else False,
        'transformer': lambda x: x,
    },
    {
        'qname': 'repo',
        'qstring': 'Repo name in gerrit',
        'validator': lambda x: True if re.match('^http(s)?://gerrit.wikimedia.org/r/', x) else False,
        'transformer': lambda x: x,
    },
    {
        'qname': 'lvs_class',
        'qstring': 'Which LVS class shall serve it (high-traffic1, high-traffic2, low-traffic)',
        'validator': lambda x: True if re.match('^[a-z0-9-]+$', x) else False,
        'transformer': lambda x: 'low-traffic',  # TODO: Actually code this
    },
    {
        'qname': 'lvs_hostname',
        'qstring': 'LVS Hostname',
        'validator': lambda x: True if re.match('^[a-z0-9]+\.svc\.(eqiad|codfw)\.wmnet$', x) else False,
        'transformer': lambda x: x,
    },
    {
        'qname': 'lvs_ip',
        'qstring': 'LVS IP',
        'validator': lambda x: True if re.match('^10(\.[0-9]{1,3}){3}$', x) else False,
        'transformer': lambda x: x,
    },
    {
        'qname': 'point_person',
        'qstring': 'Who is running point (valid username)',
        'validator': lambda x: True if re.match('^\w+$', x) else False,
        'transformer': lambda x: x,
    },
]


# Yaml formatting primitives.
# From: http://stackoverflow.com/questions/5121931
def ordered_load(stream, Loader=yaml.Loader, object_pairs_hook=OrderedDict):
    class OrderedLoader(Loader):
        pass

    def construct_mapping(loader, node):
        loader.flatten_mapping(node)
        return object_pairs_hook(loader.construct_pairs(node))

    OrderedLoader.add_constructor(
        yaml.resolver.BaseResolver.DEFAULT_MAPPING_TAG,
        construct_mapping)
    return yaml.load(stream, OrderedLoader)


def ordered_dump(data, stream=None, Dumper=yaml.Dumper, anchor_template=yaml.Dumper.ANCHOR_TEMPLATE, **kwds):
        class OrderedDumper(Dumper):
            ANCHOR_TEMPLATE = anchor_template

        def _dict_representer(dumper, data):
            return dumper.represent_mapping(
                yaml.resolver.BaseResolver.DEFAULT_MAPPING_TAG,
                data.items())
        OrderedDumper.add_representer(OrderedDict, _dict_representer)
        return yaml.dump(data, stream, OrderedDumper, **kwds)


class Service():

    def __init__(self, data):
        # TODO: Validate keys against QUESTIONS
        for k, v in data.items():
            setattr(self, k, v)

    def __str__(self):
        return '%s' % self.service_name

    def __unicode__(self):
        return u'%s' % self.__str__()

    def create_puppet_module(self):
        # Create directories
        try:
            os.makedirs('modules/%s/manifests/' % self.service_name)
            os.makedirs('modules/%s/tests/' % self.service_name)
            os.makedirs('modules/%s/templates/' % self.service_name)
        except OSError as e:
            print 'Can not create directories. Error: %s' % e
            return False

        # Populate tests
        with open('modules/%s/tests/init.pp' % self.service_name, 'w') as f:
            f.write('include ::%s\n' % self.service_name)

        with open('modules/%s/tests/Makefile' % self.service_name, 'w') as f:
            f.write('''# Test automator
MANIFESTS=$(wildcard *.pp)
OBJS=$(MANIFESTS:.pp=.po)
TESTS_DIR=$(dir $(CURDIR))
MODULE_DIR=$(TESTS_DIR:/=)
MODULES_DIR=$(dir $(MODULE_DIR))

all:    test

test:   $(OBJS)

%.po:   %.pp
\tpuppet parser validate $<
\tpuppet apply --noop --modulepath $(MODULES_DIR) $<
''')

        # Populate templates
        with open('modules/%s/templates/config.yaml.erb' % self.service_name, 'w') as f:
            f.write('# Generated by new_wmf_service.py.\n{}\n')

        # Populate manifests
        if self.service_node:
            with open('modules/%s/manifests/init.pp' % self.service_name, 'w') as f:
                f.write('''
# Class: %(name)s
#
# This class installs and configures %(name)s
#
# While only being a thin wrapper around service::node, this class exists to
# accomodate future %(name)s needs that are not suited for the service module
# classes as well as conform to a de-facto standard of having a module for every
# service
class %(name)s() {
    service::node { '%(name)s':
        port   => %(port)s,
        config => template('%(name)s/config.yaml.erb'),
    }
}
''' % {'name': self.service_name, 'port': self.port})
        return True

    def create_puppet_role(self):
        # Populate role
        if self.service_node:
            with open('manifests/role/%s.pp' % self.service_name, 'w') as f:
                f.write('''
# Role class for %(name)s
class role::%(name)s {

    system::role { 'role::%(name)s':
        description => '%(description)s',
    }

    include ::%(name)s
}

''' % {'name': self.service_name, 'description': self.service_description})
        return True

    def create_deployment_config(self):
        with open('hieradata/common/role/deployment.yaml', 'r') as f:
            data = f.read()

        repos = ordered_load(data)
        # Add our repo
        repos['repo_config']['%s/deploy' % self.service_name] = {
            'upstream': self.repo,
        }
        data = ordered_dump(repos, default_flow_style=False)
        with open('hieradata/common/role/deployment.yaml', 'w') as f:
            f.writelines(data)
        return True

    def assign_service_to_cluster(self):
        new = []
        with open('manifests/role/%s.pp' % self.cluster, 'r') as f:
            old = f.readlines()

        inroles = False
        # Poor man's parser, don't expect a Puppet DSL parser for this
        for line in old:
            match = re.search('^(\s+)include role::', line)
            if match:
                inroles = True
                indent = match.group(1)
            elif re.search('^$', line) and inroles:
                new.append('%sinclude role::%s\n' % (indent, self.service_name))
                inroles = False
            else:
                inroles = False
            new.append(line)
        with open('manifests/role/%s.pp' % self.cluster, 'w') as f:
            f.writelines(new)
        return True

    def setup_lvs_ip(self):
        with open('hieradata/role/common/%s.yaml' % self.cluster, 'r') as f:
            data = f.read()

        config = ordered_load(data)
        # Add our IP
        config['lvs::realserver::realserver_ips'].append(self.lvs_ip)
        data = ordered_dump(config, default_flow_style=False)
        with open('hieradata/role/common/%s.yaml' % self.cluster, 'w') as f:
            f.writelines(data)
        return True

    def setup_lvs(self):
        with open('hieradata/common/lvs/configuration.yaml', 'r') as f:
            data = f.read()

        config = ordered_load(data)
        # Add our IP
        # TODO: Unhardcode eqiad
        config['lvs_service_ips'][self.service_name] = {'eqiad': self.lvs_ip}
        config['lvs_services'][self.service_name] = {
            'description': self.service_description,
            'class': self.lvs_class,
            'sites': ['eqiad'],
            'ip': config['lvs_service_ips'][self.service_name],
            'port': self.port,
            'bgp': 'yes',
            'depool-threshold': '.5',
            'monitors': {
                'IdleConnection': {
                    'timeout-clean-reconnect': 3,
                    'max-delay': 300,
                }
            },
            'conftool': {
                'cluster': self.cluster,
                'service': self.service_name,
            },
            'icinga': {
                'check_command': 'check_http_lvs_on_port!%s!%s!/_info' % (self.lvs_hostname, self.port),
                'sites': {
                    'eqiad': {
                        'hostname': self.lvs_hostname,
                    }
                }
            }
        }
        data = ordered_dump(config, default_flow_style=False, anchor_template="ip_block%03d")
        with open('hieradata/common/lvs/configuration.yaml', 'w') as f:
            f.writelines(data)
        return True

    def setup_accounts(self):
        with open('hieradata/role/common/%s.yaml' % self.cluster, 'r') as f:
            data = f.read()

        config = ordered_load(data)
        # Add our new group
        config['admin::groups'].append('%s-admin' % self.service_name)
        data = ordered_dump(config, default_flow_style=False)
        with open('hieradata/role/common/%s.yaml' % self.cluster, 'w') as f:
            f.writelines(data)
        return True

    def setup_sudo_rights(self):
        with open('modules/admin/data/data.yaml', 'r') as f:
            data = f.read()

        config = ordered_load(data)
        groups = config['groups']
        # Get a suggested gid
        tmp = copy.copy(groups)
        # Temporarily drop groups without gid
        for k, v in tmp.items():
            if 'gid' not in v:
                del tmp[k]
        gids = sorted(map(lambda x: tmp[x]['gid'], tmp))
        gid = gids[-1] + 1
        newgroup = {
            'gid': gid,
            'description': 'Group of %s admins' % self.service_name,
            'members': [self.point_person],
            'privileges': [
                'ALL = NOPASSWD: /usr/sbin/service %s *' % self.service_name,
                'ALL = (%s) NOPASSWD: ALL' % self.service_name,
            ]
        }
        groups['%s-admin' % self.service_name] = newgroup
        # We avoid on purpose overriding the default flow style
        data = ordered_dump(config, width=80)
        with open('modules/admin/data/data.yaml', 'w') as f:
            f.writelines(data)
        return True

    def setup_restbase_entrypoint(self):
        # TODO: Figure out how to fill this
        return False

    def setup_varnish_entrypoint(self):
        return False

    def setup_conftool_data(self):
        filename = "conftool-data/services/services.yaml"
        with open(filename, 'r') as f:
            data = ordered_load(f)
        if self.cluster not in data:
            data[self.cluster] = {}
        # TODO: un-hardwire eqiad
        data[self.cluster][self.service_name] = {
            "port": self.port,
            "default_values": {"pooled": "yes", "weight": 10},
            "datacenters": ["eqiad"]
        }
        with open(filename, 'w') as f:
            ordered_dump(data, f, default_flow_style=False)
        return True


def question_user(answers):
    for q in QUESTIONS:
        if q['qname'] in answers and answers[q['qname']]:
            continue
        successful = False
        while not successful:
            answer = raw_input('%s? ' % q['qstring'])
            if q['validator'](answer):
                successful = True
        answers[q['qname']] = q['transformer'](answer)
    return answers


class Git():
    '''
    This class is not strictly needed. It's just a container for the member
    functions, so that they are not in the global namespace. There is no point
    in instantiating it ever
    '''

    @classmethod
    def change_branch(cls, branchname):
        args = ['checkout', branchname]
        return cls._execute_command('git', args)

    @classmethod
    def create_branch(cls, branchname, start_branch):
        args = ['branch', branchname, start_branch]
        return cls._execute_command('git', args)

    @classmethod
    def add_file(cls, f):
        args = ['add', f]
        return cls._execute_command('git', args)

    @classmethod
    def commit(cls, comment):
        args = ['commit', '-m', comment]
        return cls._execute_command('git', args)

    @classmethod
    def _execute_command(cls, command, args):
        cmd = [command]
        cmd.extend(args)
        return call(cmd)


def main():
    # Handle arguments
    answers = handle_args()
    # Get answers to questions not provided by arguments
    answers = question_user(answers)
    s = Service(answers)
    # Keep cwd
    cwd = os.getcwd()
    os.chdir('..')
    Git.create_branch(s.service_name, 'origin/production')
    Git.change_branch(s.service_name)

    if not s.create_puppet_module():
        print 'Failed to create puppet module'
        return False
    Git.add_file('modules/%s' % s.service_name)
    if not s.create_puppet_role():
        print 'Failed to create puppet role'
        return False
    Git.add_file('manifests/role/%s.pp' % s.service_name)
    if not s.create_deployment_config():
        print 'Failed to create deployment config'
        return False
    Git.add_file('hieradata/common/role/deployment.yaml')
    # Let's commit the first batch
    Git.commit('Introducing %s role and puppet module' % s.service_name)
    if not s.assign_service_to_cluster():
        print 'Failed to assign role to cluster'
        return False
    Git.add_file('manifests/role/%s.pp' % s.cluster)
    if not s.setup_accounts():
        print 'Failed to setup accounts'
        return False
    Git.add_file('hieradata/role/common/%s.yaml' % s.cluster)
    if not s.setup_sudo_rights():
        print 'Failed to setup accounts'
        return False
    Git.add_file('modules/admin/data/data.yaml')
    # Let's commit the second batch
    Git.commit('Assign %s service to %s cluster' % (s.service_name, s.cluster))
    if not s.setup_lvs_ip():
        print 'Failed to setup lvs ip'
        return False
    Git.add_file('hieradata/role/common/%s.yaml' % s.cluster)
    if not s.setup_lvs():
        print 'Failed to setup lvs'
        return False
    Git.add_file('hieradata/common/lvs/configuration.yaml')
    if not s.setup_conftool_data():
        print 'Failed to setup conftool'
        return False
    Git.add_file('conftool-data/services/services.yaml')
    # Let's commit the third batch
    Git.commit('Setup LVS for %s service on %s cluster' % (s.service_name, s.cluster))

    # Restore cwd
    os.chdir(cwd)


def handle_args():
    parser = argparse.ArgumentParser(
        description='shell helper for automating introduction of a new service')

    # Getting any answer to questions from arguments
    for q in QUESTIONS:
        parser.add_argument('--%s' % q['qname'],
                            help=q['qstring'],
                            action='store',
                            dest='%s' % q['qname'])
    parser.add_argument('-v', '--version', action='version', version='0.1beta1')
    args = parser.parse_args()
    return vars(args)

if __name__ == "__main__":
    main()
