#! /usr/bin/python3
# -*- coding: utf-8 -*-

# This script detects the role for every server running in production and
# generates stats for all systems not running the latest OS(es) (it can temporarily
# be two ones if we e.g. test-drive a new Debian release before it's released as
# stable) as to when they are planned to be migrated, how many systems are affected
# and if any systems are behind plan. A report text file is generated.

import argparse
import datetime
import os
import sys
import yaml
from collections import defaultdict
from pypuppetdb import connect
from pypuppetdb import QueryBuilder

REPORT = """
The following hosts are running the latest OS(es)

{hosts_current}

{targets_planned}

The following hosts are lagging behind the target date:

{hosts_delayed}

The following hosts are missing in the migration data:
{hosts_needdata}

The following hosts are missing a migration date:
{hosts_needplan}

The following errors were reported (malformed data:
{status_log}

A total number of {hosts_current_count} hosts are running the latest OS.

The remaining work is targeted for the following quarters:
{targets_plan}

A total number of {hosts_inplan_count} hosts are being migrated and according to plan.
A total number of {hosts_delayed_count} hosts are being migrated and lagging behind plan.
A total number of {hosts_needdata_count} hosts need further migration data.
A total number of {hosts_needplan_count} hosts need further planning/discussion.

"""


def connect_puppetdb(puppetdb_host):
    db = connect(host=puppetdb_host,
                 port=443,
                 protocol='https',
                 ssl_key=None,
                 ssl_cert=None,
                 ssl_verify='/var/lib/puppet/ssl/certs/ca.pem')
    return db


def get_servers_running_os(distro_release, puppetdb_host):
    pdb = connect_puppetdb(puppetdb_host)
    facts = pdb.facts('lsbdistcodename', distro_release)

    return [fact.node for fact in facts]


# Parse a YAML file with a list of role names which defines meta
# data for the services, e.g:
# role::foo
#  owner: Foo SREs (point of contact) (optional)
#  target-q: 2020-4 (target quarter by which this service will be
#                    fully migrated to the current OS(es)
#  phab-task: 123456 (reference to Phabricator) (optional)
def parse_services(yaml_file):
    try:
        with open(yaml_file, "r") as stream:
            servicesfile = yaml.safe_load(stream)

    except IOError:
        print("Error: Could not open {}".format(yaml_file))
        sys.exit(1)

    except yaml.scanner.ScannerError as e:
        print("Invalid YAML file:")
        print(e)
        sys.exit(1)

    return servicesfile


def get_current_quarter():
    today = datetime.datetime.now()

    return "{}-{}".format(today.year, (today.month-1)//3+1)


# Fetch all roles and return a dictionary of fdqn[rolename]
def get_roles(puppetdb_host):
    fqdns_roles = {}

    q = QueryBuilder.ExtractOperator()
    q.add_field(str('tags'))
    q.add_field(str('title'))
    q.add_field(str('certname'))
    q.add_query(QueryBuilder.EqualsOperator('type', 'System::Role'))

    pdb = connect_puppetdb(puppetdb_host)
    data = pdb._query('resources', query=q)

    for resource in data:
        for i in resource['tags']:
            if i.startswith("role::"):
                fqdns_roles[resource['certname']] = i

    return fqdns_roles


# Returns True if the target quarter is within the current quarter or the future
# current_quarter, target_quarter are strings like "2020-3"
def quarter_in_plan(current_quarter, target_quarter):
    current_year = current_quarter.split("-")[0]
    current_quarter = current_quarter.split("-")[1]
    target_year = target_quarter.split("-")[0]
    target_quarter = target_quarter.split("-")[1]

    if current_year > target_year:
        return False

    elif current_year == target_year:
        if current_quarter > target_quarter:
            return False

    return True


def unroll_result_list(entries):
    return '\n'.join(sorted(entries))


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('-p', '--puppetdb', required=True,
                        help='The hostname of the PuppetDB server')
    parser.add_argument('-s', '--serviceslist', required=True,
                        help='A YAML file with all services, owners and planned migration dates')

    args = parser.parse_args()
    owners = parse_services(args.serviceslist)
    current_quarter = get_current_quarter()

    status_log = []
    hosts_delayed = []
    hosts_inplan = []
    hosts_needplan = []
    hosts_needdata = []
    hosts_current = []

    deprecated_os = ['stretch']
    current_os = ['buster']

    targets = defaultdict(list)
    roles = get_roles(args.puppetdb)

    for distro in current_os:
        hosts_current += get_servers_running_os(distro, args.puppetdb)

    for distro in deprecated_os:
        hosts = get_servers_running_os(distro, args.puppetdb)

        for host in hosts:

            if host not in roles:
                status_log.append("Malformed entry for {}, no role found".format(host))
                continue

            role = roles[host]

            if not owners.get(role, None):
                hosts_needdata.append("{} running role {}".format(host, role))
                continue

            owner_def = owners.get(role)

            target_quarter = owner_def.get('target-q', 'TBD')
            if target_quarter == 'TBD':
                hosts_needplan.append("{} running role {}".format(host, role))
                continue

            targets[target_quarter].append(host)

            if quarter_in_plan(current_quarter, target_quarter):
                hosts_inplan.append(host)
            else:
                hosts_delayed.append(host)

    datetime_stamp = datetime.datetime.now().strftime("%Y-%m-%d")
    file_name = 'os-report-{}.txt'.format(datetime_stamp)
    if os.path.exists(file_name):
        print('{file_name}: already exists, skipping generation of OS report'.format(
            file_name=file_name))
    else:
        targets_planned = ''
        targets_plan = ''
        for i in sorted(targets):
            targets_planned += '\n\nThe following hosts are/were planned for {} ' \
                ':\n{}'.format(i, unroll_result_list(targets[i]))
            targets_plan += "- {} systems are planned for {}\n".format(len(targets[i]), i)

        with open(file_name, 'w') as report:
            report.write(REPORT.format(
                hosts_current=unroll_result_list(hosts_current),
                targets_planned=targets_planned,
                hosts_delayed=unroll_result_list(hosts_delayed),
                hosts_needdata=unroll_result_list(hosts_needdata),
                hosts_needplan=unroll_result_list(hosts_needplan),
                status_log=unroll_result_list(status_log),
                targets_plan=targets_plan,
                hosts_current_count=len(hosts_current),
                hosts_inplan_count=len(hosts_inplan),
                hosts_delayed_count=len(hosts_delayed),
                hosts_needdata_count=len(hosts_needdata),
                hosts_needplan_count=len(hosts_needplan),
            ))


if __name__ == '__main__':
    main()
