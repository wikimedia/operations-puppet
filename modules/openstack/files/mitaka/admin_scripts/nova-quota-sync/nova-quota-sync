#!/usr/bin/env python
#
# Copyright (c) 2014 CERN
# All Rights Reserved.
#
#    Licensed under the Apache License, Version 2.0 (the "License"); you may
#    not use this file except in compliance with the License. You may obtain
#    a copy of the License at
#
#         http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
#    WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
#    License for the specific language governing permissions and limitations
#    under the License.
#
# Author:
#  Belmiro Moreira <belmiro.moreira@cern.ch>

import argparse
import sys
import ConfigParser
import datetime

from prettytable import PrettyTable
from sqlalchemy import and_
from sqlalchemy import delete
from sqlalchemy import func
from sqlalchemy import MetaData
from sqlalchemy import select
from sqlalchemy import Table
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.ext.declarative import declarative_base



def makeConnection(db_url):
    engine = create_engine(db_url)
    engine.connect()
    Session = sessionmaker(bind=engine)
    thisSession = Session()
    metadata = MetaData()
    metadata.bind = engine
    Base = declarative_base()
    tpl = thisSession, metadata, Base

    return tpl


def update_quota_usages(meta, usage):

    if usage['in_sync']:
        print "[ERROR] already in sync"
        return

    instances = 0
    cores = 0
    ram = 0

    for (inst_project_id, inst_user_id, inst_instances, inst_cores,
            inst_ram) in resources_project_user_usage_projectid(meta,
            usage['project_id']):
        if usage['project_id'] == inst_project_id and\
            usage['user_id'] == inst_user_id:
            instances = inst_instances
            cores = inst_cores
            ram = inst_ram

    instances_quota_usage = 0
    cores_quota_usage = 0
    ram_quota_usage = 0

    quota_usage = resources_project_user_quota_usage(meta, usage['project_id'],
        usage['user_id'])

    for (quota_resource, quota_in_use) in quota_usage:
        if quota_resource == 'instances':
            instances_quota_usage = quota_in_use
        elif quota_resource == 'cores':
            cores_quota_usage = quota_in_use
        elif quota_resource == 'ram':
            ram_quota_usage = quota_in_use

    changed = False
    if usage['instances'] != instances:
        changed = True
    if usage['cores'] != cores:
        changed = True
    if usage['ram'] != ram:
        changed = True
    if usage['instances_quota_usage'] != instances_quota_usage:
        changed = True
    if usage['cores_quota_usage'] != cores_quota_usage:
        changed = True
    if usage['ram_quota_usage'] != ram_quota_usage:
        changed = True

    if changed == True:
        print ("[skiping sync] Values changed meanwhile. project_id:%s user_id:%s" % (usage['project_id'], usage['user_id']))
        return

    if usage['instances'] != usage['instances_quota_usage']:
        update_quota_usages_db(meta, usage['project_id'], usage['user_id'],
            'instances', usage['instances'])
    if usage['cores'] != usage['cores_quota_usage']:
        update_quota_usages_db(meta, usage['project_id'], usage['user_id'],
            'cores', usage['cores'])
    if usage['ram'] != usage['ram_quota_usage']:
        update_quota_usages_db(meta, usage['project_id'], usage['user_id'],
            'ram', usage['ram'])


def update_quota_usages_db(meta, project_id, user_id, resource, in_use):
    quota_usages = Table('quota_usages', meta, autoload=True)
    now = datetime.datetime.utcnow() 
    quota = select(columns=[quota_usages.c.user_id],
            whereclause=and_(quota_usages.c.user_id == user_id,
                quota_usages.c.project_id == project_id,
                quota_usages.c.resource == resource)).execute().fetchone()

    if not quota:
        quota_usages.insert().values(created_at=now, updated_at=now,
                project_id=project_id, resource=resource, in_use=in_use,
                reserved=0, deleted=0, user_id=user_id).execute()
    else:
        quota_usages.update().where(and_(quota_usages.c.user_id == user_id,
            quota_usages.c.project_id == project_id,
            quota_usages.c.resource == resource)).values(updated_at=now,
                    in_use=in_use).execute()


def display(resources_usage, all_resources=False):
    ptable = PrettyTable(["Project ID", "User ID", "Instances", "Cores",
        "Ram", "Status"])

    for usage in resources_usage:
        if not usage['in_sync']:
            if usage['instances'] != usage['instances_quota_usage']:
                instances = str(usage['instances_quota_usage']) + ' -> ' + str(usage['instances'])
            else:
                instances = usage['instances']
            if usage['cores'] != usage['cores_quota_usage']:
                cores = str(usage['cores_quota_usage']) + ' -> ' + str(usage['cores'])
            else:
                cores = usage['cores']
            if usage['ram'] != usage['ram_quota_usage']:
                ram = str(usage['ram_quota_usage']) + ' -> ' + str(usage['ram'])
            else:
                ram = usage['ram']

            ptable.add_row([usage['project_id'], usage['user_id'],
                instances, cores, ram,
                '\033[1m\033[91mMismatch\033[0m'])

        if usage['in_sync'] and all_resources:
            ptable.add_row([usage['project_id'], usage['user_id'],
                usage['instances'], usage['cores'], usage['ram'],
                '\033[1m\033[92mOK\033[0m'])

    print '\n'
    print ptable


def analise_project_user_usage(resources_usage):
    for usage in resources_usage:
        in_sync = True
        if usage['instances'] != usage['instances_quota_usage']:
            in_sync = False
        elif usage['cores'] != usage['cores_quota_usage']:
            in_sync = False
        elif usage['ram'] != usage['ram_quota_usage']:
            in_sync = False
        usage['in_sync'] = in_sync

    return resources_usage


def project_user_usage(meta, project):
    resources_usage = []
    if project:
        resources_project_user_usage = resources_project_user_usage_projectid
    else:
        resources_project_user_usage = resources_project_user_usage_all

    for (project_id, user_id, instances, cores,
            ram) in resources_project_user_usage(meta, project):

        instances_quota_usage = 0
        cores_quota_usage = 0
        ram_quota_usage = 0

        quota_usage = resources_project_user_quota_usage(meta, project_id,
            user_id)

        for (quota_resource, quota_in_use) in quota_usage:
            if quota_resource == 'instances':
                instances_quota_usage = quota_in_use
            elif quota_resource == 'cores':
                cores_quota_usage = quota_in_use
            elif quota_resource == 'ram':
                ram_quota_usage = quota_in_use

        resources_usage.append({'user_id': user_id,
                              'project_id': project_id,
                              'instances': instances,
                              'cores': cores,
                              'ram': ram,
                              'instances_quota_usage': instances_quota_usage,
                              'cores_quota_usage': cores_quota_usage,
                              'ram_quota_usage': ram_quota_usage,
                              'in_sync': None})

    quotas_usage_all = resources_project_user_quota_usage_all(meta)
    for (project_id, user_id) in quotas_usage_all:
        if project and project != project_id:
            continue
        element = filter(lambda element: element['project_id'] == project_id and element['user_id'] == user_id, resources_usage)
        if not element:
            instances_quota_usage = 0
            cores_quota_usage = 0
            ram_quota_usage = 0

            quota_usage = resources_project_user_quota_usage(meta, project_id,
                user_id)

            for (quota_resource, quota_in_use) in quota_usage:
                if quota_resource == 'instances':
                    instances_quota_usage = quota_in_use
                elif quota_resource == 'cores':
                    cores_quota_usage = quota_in_use
                elif quota_resource == 'ram':
                    ram_quota_usage = quota_in_use

            resources_usage.append({'user_id': user_id,
                                  'project_id': project_id,
                                  'instances': 0,
                                  'cores': 0,
                                  'ram': 0,
                                  'instances_quota_usage': instances_quota_usage,
                                  'cores_quota_usage': cores_quota_usage,
                                  'ram_quota_usage': ram_quota_usage,
                                  'in_sync': None})
    return resources_usage


def resources_project_user_usage_all(meta, project_id):
    instances = Table('instances', meta, autoload=True)

    resources_usage = select(
        columns=[instances.c.project_id, instances.c.user_id,
            func.count(instances.c.id), func.sum(instances.c.vcpus),
            func.sum(instances.c.memory_mb)],
        whereclause=instances.c.deleted == 0,
        group_by=[instances.c.project_id, instances.c.user_id])

    return resources_usage.execute()


def resources_project_user_usage_projectid(meta, project_id):
    instances = Table('instances', meta, autoload=True)

    resources_usage = select(
        columns=[instances.c.project_id, instances.c.user_id,
            func.count(instances.c.id), func.sum(instances.c.vcpus),
            func.sum(instances.c.memory_mb)],
        whereclause=and_(instances.c.project_id == project_id,
            instances.c.deleted == 0),
        group_by=[instances.c.project_id, instances.c.user_id])

    return resources_usage.execute()


def resources_project_user_quota_usage_all(meta):
    quota_usages = Table('quota_usages', meta, autoload=True)

    resource_quota_usage = select(
        columns=[quota_usages.c.project_id, quota_usages.c.user_id],
        whereclause= quota_usages.c.deleted == 0,
        group_by=[quota_usages.c.project_id, quota_usages.c.user_id])

    return resource_quota_usage.execute()


def resources_project_user_quota_usage(meta, project_id, user_id):
    quota_usages = Table('quota_usages', meta, autoload=True)

    resource_quota_usage = select(
        columns=[quota_usages.c.resource, quota_usages.c.in_use],
        whereclause=and_(quota_usages.c.user_id == user_id,
            quota_usages.c.project_id == project_id,
            quota_usages.c.deleted == 0))

    return resource_quota_usage.execute()


def sync_resources(meta, resources_chk, auto_sync):
    for resource in resources_chk:
        if resource['in_sync']:
            continue
        if auto_sync:
            update_quota_usages(meta, resource)
        else:
            display([resource])
            if yn_choice():
                update_quota_usages(meta, resource)
            else:
                print "[skiping sync]"


def yn_choice():
    yes = set(['yes','y', 'ye'])
    no = set(['no','n'])
    abort = set(['a', 'ab', 'abo', 'abor', 'abort'])

    print "Do you want to sync? [Yes/No/Abort]"
    while True:
        choice = raw_input().lower()
        if choice in yes:
           return True
        elif choice in no:
           return False
        elif choice in abort:
            sys.exit(1)
        else:
           sys.stdout.write("Do you want to sync? [Yes/No/Abort]")


def show_quota_resources(meta, all_resources=False, no_sync=False, auto_sync=False, project_id=None):
    resources = project_user_usage(meta, project_id)
    resources_chk = analise_project_user_usage(resources)
    display(resources_chk, all_resources)
    if not no_sync:
        sync_resources(meta, resources_chk, auto_sync)


def get_db_url(config_file):
    parser = ConfigParser.SafeConfigParser()
    try:
        parser.read(config_file)
        db_url = parser.get('database', 'connection')
    except:
        print "ERROR: Check nova configuration file."
        sys.exit(2)
    return db_url


def parse_cmdline_args():
    parser = argparse.ArgumentParser()
    parser.add_argument("--all",
        action="store_true",
        help="show the state of all quota resources")
    parser.add_argument("--no_sync",
        action="store_true",
        help="don't perform any synchronization of the mismatch resources")
    parser.add_argument("--auto_sync",
        action="store_true",
        help="automatically sync all resources (no interactive)")
    parser.add_argument("--project_id",
        type=str,
        help="searches only project ID")
    parser.add_argument("--config",
        default='/etc/nova/nova.conf',
        help='configuration file')
    return parser.parse_args()


def main():
    try:
        args = parse_cmdline_args()
    except Exception as e:
        sys.stdout.write("Wrong command line arguments (%s)" % e.strerror)

    db_url = get_db_url(args.config)
    nova_session, nova_metadata, nova_Base = makeConnection(db_url)
    show_quota_resources(nova_metadata, args.all, args.no_sync, args.auto_sync, args.project_id)


if __name__ == "__main__":
    main()
