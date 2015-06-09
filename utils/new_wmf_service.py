#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
  new_service -- shell helper for automating introduction of a new service

  Usage: ./new_service.py

  Requirements: Running it from the utils/ directory

  Copyright 2015 Alexandros Kosiaris <akosiaris@wikimedia.org>
  Licensed under the Apache license.
"""

import re
import os
import argparse
import yaml

QUESTIONS = [
    {
        'qname': 'service_name',
        'qstring': 'What will be the name of the service',
        'validator': lambda x: True if re.match('^[a-z_-]{6,20}$', x) else False,
        'transformer': lambda x: x,
    },
    {
        'qname': 'service_description',
        'qstring': 'A one line description of the service',
        'validator': lambda x: True if re.match('^[\w\s\.-]+$', x) else False,
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
        'validator': lambda x: True if re.match('^[a-z-]+$', x) else False,
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


class Service():

    def __init__(self, data):
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
            data = f.readlines()

        data = ''.join(data)
        repos = yaml.load(data)
        # Add our repo
        repos['repo_config']['%s/deploy' % self.service_name] = {
                'upstream': self.repo,
                }
        data = yaml.dump(repos, default_flow_style=False)
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

    def setup_lvs(self):
        return False

    def setup_accounts(self):
        with open('hieradata/role/common/%s.yaml' % self.cluster, 'r') as f:
            data = f.readlines()

        data = ''.join(data)
        config = yaml.load(data)
        # Add our new group
        config['admin::groups'].append('%s-admin' % self.service_name)
        data = yaml.dump(config, default_flow_style=False)
        with open('hieradata/role/common/%s.yaml' % self.cluster, 'w') as f:
            f.writelines(data)
        return True

    def setup_sudo_rights(self):
        with open('modules/admin/data/data.yaml', 'r') as f:
            data = f.readlines()

        data = ''.join(data)
        config = yaml.load(data)
        groups = config['groups']
        # Get a suggested gid
        tmp = groups
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
        data = yaml.dump(config, width=80)
        with open('modules/admin/data/data.yaml', 'w') as f:
            f.writelines(data)
        return True

    def setup_restbase_entrypoint(self):
        # TODO: Figure out how to fill this
        return False

    def setup_varnish_entrypoint(self):
        return False


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


def main():
    # Handle arguments
    answers = handle_args()
    # Get answers to questions not provided by arguments
    answers = question_user(answers)
    s = Service(answers)
    # Keep cwd
    cwd = os.getcwd()
    os.chdir('..')

    if not s.create_puppet_module():
        print 'Failed to create puppet module'
        return False
    if not s.create_puppet_role():
        print 'Failed to create puppet role'
        return False
    if not s.assign_service_to_cluster():
        print 'Failed to assign role to cluster'
        return False
    if not s.create_deployment_config():
        print 'Failed to create deployment config'
        return False
    if not s.setup_accounts():
        print 'Failed to setup accounts'
        return False
    if not s.setup_sudo_rights():
        print 'Failed to setup accounts'
        return False

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
