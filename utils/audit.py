#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
"""audit for unused modules"""
import re
import logging

from argparse import ArgumentParser
from collections import defaultdict
from pathlib import Path

from pypuppetdb import connect
from pypuppetdb.QueryBuilder import ExtractOperator
from requests import get
from bs4 import BeautifulSoup


def get_puppetdb_resources():
    """Get a list of unique resource inuse by the puppetdb

    This functions assumes one can connecto puppetdb:8080 i.e.
    add the following to /etc/hosts
        127.0.0.1       puppetdb
    and:
        ssh -L8080:localhost:8080 puppetdb1002.eqiad.wmnet
    """
    unique_resources = set()
    db = connect()
    extract = ExtractOperator()
    extract.add_field(['type', 'title'])
    # TODO: this is pretty slow as it gets all resources then dose a unique
    # would be better to do a select distinct via the api
    resources = db._query('resources', query=extract)
    for resource in resources:
        # if we have a class we want the title to know which class
        if resource['type'] == 'Class':
            unique_resources.add(resource['title'].lower())
        else:
            unique_resources.add(resource['type'].lower())
    return unique_resources


# TODO: this should probably be a ruby script as we can likely just load a
# manifests file and get an easy list of resources
def get_resources(manifest):
    """parse a manifest for all puppet resources"""
    resources = set()
    class_matcher = re.compile(r'\s+class\s*\{\s*[\'"](?P<name>[^\'"]+)')
    include_matcher = re.compile(r'\s+(include|require|contain)\s+(?P<name>[\w:]+)')
    resource_matcher = re.compile(r'\s+(?P<name>[\w:]+)\s*\{\s*(?:[^:]+:|$)')
    create_resource_matcher = re.compile(
        r'\s+create_resources\((?P<name>[^,]+),\s*(?P<params>[^\),]+)\s*[,\)]')
    for line in manifest.read_text().splitlines():
        for matcher in [class_matcher, include_matcher, resource_matcher]:
            match = re.match(matcher, line)
            if match:
                if match['name'].endswith(':'):
                    # deals with false pos `default: {`
                    continue
                name = match['name'].lstrip(':').lower()
                logging.debug('%s: %s (%s)', name, matcher, line)
                resources.add(name)
                break
        match = re.match(create_resource_matcher, line)
        if match:
            name = match['name'].strip('"').strip("'").lstrip(':')
            if name == 'class':
                # params for a class look like `{'ssh::server' => $ssh_server_settings}`
                bad_chars = re.compile('[{\'"]')
                name = bad_chars.sub('', match['params'].split()[0]).lstrip(':')
            logging.debug('%s: %s (%s)', name, matcher, line)
            resources.add(name)

    return resources


def get_class_resources(puppet_repo):
    """Return a list of puppet files excluding bundle and spec folders"""
    ignored_dirs = ['.bundle', 'spec']
    third_party_modules = ['lvm', 'stdlib', 'puppetdbquery']
    # path is $prefix/$modules/manifests
    name_matcher = re.compile(r'modules\/(?P<module>[^\/]+)\/manifests\/(?P<name>[^\.]+)\.pp')
    # we dont care about functions and types so just scan manifests
    pp_files = puppet_repo.glob('modules/**/manifests/**/*.pp')
    class_resources = {}
    for path in pp_files:
        if any(part in path.parts for part in ignored_dirs):
            # ignore spec and bundle dirs
            continue
        match = re.search(name_matcher, str(path))
        if not match:
            # This shouldn't happen
            continue
        if match['module'] in third_party_modules:
            continue
        name = '::'.join(match['name'].split('/')).lower().strip()
        name = f"{match['module']}::{name}"
        if name.endswith('::init'):
            name = name[:-6]
        class_resources[name] = get_resources(path)
    return class_resources


def get_used_production_roles(site_pp):
    """Parse site.pp for a set of roles"""
    roles = set()
    for line in site_pp.read_text().splitlines():
        match = re.match(r'\s+role\((?P<role>[\w:]+)\)', line)
        if match:
            roles.add(f'role::{match["role"]}')
            continue
        # match for policy violations
        match = re.match(r'\s+(:?include|require)\s+(?P<role>[\w:]+)', line)
        if match:
            roles.add(match['role'].lstrip(':'))
    return roles


def get_keystone_resources():
    """scrap the keystone browse for resources"""
    # We should add an endpoint listing all resources
    req = get('https://openstack-browser.toolforge.org/puppetclass/')
    soup = BeautifulSoup(req.content, features='lxml')
    panel = soup.findAll('div', attrs={'class': 'panel-body'})
    return {a.text.lower() for a in panel[0].findAll('a')}


def get_args():
    """Parse arguments

    Returns:
        `argparse.Namespace`: The parsed argparser Namespace
    """
    parser = ArgumentParser(description=__doc__)
    parser.add_argument('-v', '--verbose', action='count')
    parser.add_argument('-p', '--puppet-repo', type=Path, default=Path(__file__).parents[1])
    group = parser.add_mutually_exclusive_group()
    group.add_argument('-d', '--depends',
                       help='if present show the resources this resource depends on')
    group.add_argument('-r', '--rdepends',
                       help='if present show the resources this resource depends on')
    group.add_argument('--puppetdb', action='store_true', help='also use data from puppetdb')
    return parser.parse_args()


def get_log_level(args_level):
    """Convert an integer to a logging log level

    Parameters:
        args_level (int): The log level as an integer

    Returns:
        `logging.loglevel`: the logging loglevel
    """
    return {
        None: logging.ERROR,
        1: logging.WARN,
        2: logging.INFO,
        3: logging.DEBUG}.get(args_level, logging.DEBUG)


def audit1(class_resources, used_production_role, keystone_resources):
    """Audit files"""
    # This is a less strict audit function, keeping around for a bit to make sure audit works
    unused_resources = set()
    for title in class_resources:
        if title in used_production_role:
            logging.debug('%s: used as a production role', title)
            continue
        if title in keystone_resources:
            logging.debug('%s: defined in keystone', title)
            continue
        # get a list of resource which use this resource
        # Should be able to optimise this somehow
        implementors = [_title for _title, resources in class_resources.items()
                        if title in resources]
        if implementors:
            logging.debug('%s - is used by: %s', title, ','.join(implementors))
            continue
        unused_resources.add(title)
    return unused_resources


def contained_resources(title, class_resources, all_resources):
    """recursively search class_resources"""
    if title in all_resources:
        return all_resources
    all_resources.add(title)
    for resource in class_resources.get(title, []):
        if resource in all_resources:
            continue
        all_resources.update(contained_resources(resource, class_resources, all_resources))
    return all_resources


def audit(class_resources, all_resources):
    """audit files"""
    used_resources = set()
    for title in sorted(all_resources):
        used_resources.update(contained_resources(title, class_resources, used_resources))
    return set(class_resources.keys()) - used_resources


def get_rdepends(resources):
    """Take a dict of resource => depends and return resource => rdepends"""
    rdepends = defaultdict(set)
    for resource, depends in resources.items():
        for depend in depends:
            rdepends[depend].add(resource)
    return rdepends


def main():
    """main entry point

    Returns:
        int: an int representing the exit code
    """
    args = get_args()
    logging.basicConfig(level=get_log_level(args.verbose))

    repo_dir = args.puppet_repo.expanduser()
    used_production_role = get_used_production_roles(repo_dir / 'manifests' / 'site.pp')
    keystone_resources = get_keystone_resources()
    class_resources = get_class_resources(repo_dir)
    if args.depends:
        resources = contained_resources(args.depends, class_resources, set())
    elif args.rdepends:
        rdepends = get_rdepends(class_resources)
        resources = contained_resources(args.rdepends, rdepends, set())
    else:
        resources = audit(class_resources, used_production_role | keystone_resources)
        if args.puppetdb:
            logging.info('fetching puppetdb resources, this can take a few mins')
            puppetdb_resources = get_puppetdb_resources()
            false_posatives = puppetdb_resources & resources
            if false_posatives:
                for res in false_posatives:
                    logging.warning('%s: only found in puppetdb', res)
                resources = resources - false_posatives
        else:
            print('### WARNING WARNING WARNING WARNING WARNING WARNING ###')
            print('### you are not using puppetdb results will not be  ###')
            print('### 100% accurate. Use --puppetdb switch to improve ###')
            print('### WARNING WARNING WARNING WARNING WARNING WARNING ###')
        for res in sorted(resources):
            print(res)
        print('### WARNING: This script has not been well scrutinized be sceptical of results ###')

    return 0


if __name__ == '__main__':
    raise SystemExit(main())
