#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
pcc -- shell helper for the Puppet catalog compiler

Usage: pcc [--api-token TOKEN] [--username USERNAME] CHANGE NODES

Required arguments:
CHANGE                 Gerrit change number, change ID, or Git commit.
                        (May be 'latest' or 'HEAD' for the last commit.)
NODES                  Comma-separated list of nodes. '.eqiad.wmnet'
                        will be appended for any unqualified host names.

Optional arguments:
--api-token TOKEN      Jenkins API token. Defaults to JENKINS_API_TOKEN.
--username USERNAME    Jenkins user name. Defaults to JENKINS_USERNAME.
--future               If present, will run the change through the future
                        parser

Examples:
$ pcc latest mw1031,mw1032

You can get your API token by clicking on your name in Jenkins and then
clicking on 'configure'.

pcc requires the jenkinsapi python module:
https://pypi.python.org/pypi/jenkinsapi (try `pip install jenkinsapi`)

Copyright 2014 Ori Livneh <ori@wikimedia.org>
Licensed under the Apache license.
"""

import argparse
import json
import os
import re
import subprocess
import time

try:
    import urllib2
except ImportError:
    import urllib.request as urllib2

try:
    import jenkinsapi
except ImportError:
    raise SystemExit("""You need the `jenkinsapi` module. Try `pip install jenkinsapi`
or `sudo apt-get install python3-jenkinsapi` (if available on your distro).""")


JENKINS_URL = 'https://integration.wikimedia.org/ci/'
GERRIT_URL_FORMAT = ('https://gerrit.wikimedia.org/r/changes/'
                     'operations%%2Fpuppet~production~%s/detail')


def format_console_output(text):
    """Colorize log output."""
    return (re.sub(r'((?<=\n) +|(?<=Finished: )\w+)', '', text, re.M)
            .replace('\n', '\x1b[0m\n')
            .replace('INFO:', '\x1b[94mINFO:')
            .replace('ERROR:', '\x1b[91mINFO:'))


def get_change_id(change='HEAD'):
    """Get the change ID of a commit (defaults to HEAD)."""
    commit_message = subprocess.check_output(['git', 'log', '-1', change],
                                             universal_newlines=True)
    match = re.search('(?<=Change-Id: )(?P<id>.*)', commit_message)
    return match.group('id')


def get_gerrit_blob(url):
    """Return a json blob from a gerrit API endpoint

    Arguments:
        url (str): The gerrit API url

    Returns
        dict: A dictionary representing the json blob returned by gerrit

    """
    req = urllib2.urlopen(url)
    # To prevent against Cross Site Script Inclusion (XSSI) attacks, the JSON response
    # body starts with a magic prefix line: `)]}'` that must be stripped before feeding the
    # rest of the response body to a JSON
    # https://gerrit-review.googlesource.com/Documentation/rest-api.html#output
    return json.loads(req.read().split(b'\n', 1)[1])


def get_change_number(change_id):
    """Resolve a change ID to a change number via a Gerrit API lookup."""
    res = get_gerrit_blob(GERRIT_URL_FORMAT % change_id)
    return res['_number']


def get_change(change):
    """Resolve a Gerrit change

    Arguments
        change (str): the change ID or change number to test.  To test HEAD pass last or latest

    Returns
        int: the change number or -1 to indicate a faliure

    """
    if change.isdigit():
        return int(change)
    if change.startswith('I'):
        return get_change_number(change)
    if change in ('latest', 'last'):
        change_id = get_change_id('HEAD')
        return get_change_number(change_id)
    return -1


def parse_nodes(string_list, default_suffix='.eqiad.wmnet'):
    """If nodes contains ':' as the second character then the string_list
    is returned unmodified assuming it is a host variable override.
    https://wikitech.wikimedia.org/wiki/Help:Puppet-compiler#Host_variable_override

    Otherwise qualify any unqualified nodes in a comma-separated list by
    appending a default domain suffix."""
    if string_list.startswith(('P:', 'C:', 'O:', 're:', 'parse_commit')):
        return string_list
    return ','.join(node if '.' in node else node + default_suffix
                    for node in string_list.split(','))


class ParseCommitException(Exception):
    """Raised when no hosts found"""


def parse_commit(change):
    """Parse a commit message looking for a Hosts: lines

    Arguments:
        change (str): the change number to use

    Returns:
        str: The lists of hosts or an empty string

    """
    hosts = []
    commit_url = ('https://gerrit.wikimedia.org/r/changes/?q={}'
                  '&o=CURRENT_REVISION&o=CURRENT_COMMIT&o=COMMIT_FOOTERS')
    res = get_gerrit_blob(commit_url.format(change))

    for result in res:
        if result['_number'] != change:
            continue
        commit = result['revisions'][result['current_revision']]['commit_with_footers']
        break
    else:
        raise ParseCommitException('No Hosts found')

    for line in commit.splitlines():
        if line.startswith('Hosts:'):
            hosts.append(line.split(':', 1)[1].strip())

    return ','.join(hosts)


def get_args():
    """Parse Arguments"""

    parser = argparse.ArgumentParser(description=__doc__,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('change', type=get_change,
                        help='The change number or change ID to test. '
                             'Alternatively last or latest to test head')
    parser.add_argument('nodes', type=parse_nodes,
                        help='Either a Comma-separated list of nodes or a Host Variable Override. '
                             'Alternatively use `parse_commit` to parse')
    parser.add_argument('--api-token', default=os.environ.get('JENKINS_API_TOKEN'),
                        help='Jenkins API token. Defaults to JENKINS_API_TOKEN.')
    parser.add_argument('--username', default=os.environ.get('JENKINS_USERNAME'),
                        help='Jenkins user name. Defaults to JENKINS_USERNAME.')
    return parser.parse_args()


def main():
    """Main Entry Point"""
    args = get_args()
    if args.change == -1:
        print("Unable to find change ID")
        return 1
    if not args.api_token or not args.username:
        print('You must either provide the --api-token and --username options'
              ' or define JENKINS_API_TOKEN and JENKINS_USERNAME in your env.')
        return 1

    red, green, yellow, white = [('\x1b[9%sm{}\x1b[0m' % n).format for n in (1, 2, 3, 7)]

    jenkins = jenkinsapi.jenkins.Jenkins(
        baseurl=JENKINS_URL,
        username=args.username,
        password=args.api_token
    )

    print(yellow('Compiling %(change)s on node(s) %(nodes)s...' % vars(args)))
    try:
        nodes = parse_commit(args.change) if args.nodes == 'parse_commit' else args.nodes
    except KeyError as error:
        print('Unable to find commit message: {}'.format(error))
        return 1
    except ParseCommitException as error:
        print(error)
        return 1

    job = jenkins.get_job('operations-puppet-catalog-compiler')
    build_params = {
        'GERRIT_CHANGE_NUMBER': str(args.change),
        'LIST_OF_NODES': nodes,
        'COMPILER_MODE': 'change',
    }

    invocation = job.invoke(build_params=build_params)

    try:
        invocation.block_until_building()
    except AttributeError:
        invocation.block(until='not_queued')

    build = invocation.get_build()

    print('Your build URL is %s' % white(build.baseurl))

    running = True
    output = ''
    while running:
        time.sleep(1)
        running = invocation.is_running()
        new_output = build.get_console().rstrip('\n')
        console_output = format_console_output(new_output[len(output):]).strip()
        if console_output:
            print(console_output)
        output = new_output

    # Puppet's exit code is not always meaningful, so we grep the output
    # for failures before declaring victory.
    if ('Run finished' in output and not re.search(r'[1-9]\d* (ERROR|FAIL)', output)):
        print(green('SUCCESS'))
        return 0
    print(red('FAIL'))
    return 1


if __name__ == '__main__':
    raise SystemExit(main())
