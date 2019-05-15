#!/usr/bin/env python
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
from __future__ import print_function

import sys
try:
    reload(sys)
    sys.setdefaultencoding('utf-8')
except NameError:
    pass  # python3 FTW

import argparse
import json
import os
import re
import subprocess
import textwrap
import time

try:
    import urllib2
except ImportError:
    import urllib.request as urllib2

try:
    import jenkinsapi
except ImportError:
    sys.exit('You need the `jenkinsapi` module. Try `pip install jenkinsapi`.')


JENKINS_URL = 'https://integration.wikimedia.org/ci/'
GERRIT_URL_FORMAT = ('https://gerrit.wikimedia.org/r/changes/'
                     'operations%%2Fpuppet~production~%s/detail')
red, green, yellow, blue, white = [
    ('\x1b[9%sm{}\x1b[0m' % n).format for n in (1, 2, 3, 4, 7)]


def format_console_output(text):
    """Colorize log output."""
    return (re.sub(r'((?<=\n) +|(?<=Finished: )\w+)', '', text, re.M)
              .replace('\n', '\x1b[0m\n')
              .replace('INFO:', '\x1b[94mINFO:')
              .replace('ERROR:', '\x1b[91mINFO:'))


def get_change_id(change='HEAD'):
    """Get the change ID of a commit (defaults to HEAD)."""
    commit_message = subprocess.check_output(['git', 'log', '-1', change])
    match = re.search('(?<=Change-Id: )(?P<id>.*)', commit_message)
    return match.group('id')


def get_change_number(change_id):
    """Resolve a change ID to a change number via a Gerrit API lookup."""
    req = urllib2.urlopen(GERRIT_URL_FORMAT % change_id)
    res = json.loads(req.read()[4:])
    return res['_number']


def get_change(change):
    """Resolve a Gerrit change, specified as either a change ID or a Git
    commit, to a Gerrit change number."""
    if change.isdigit():
        return int(change)
    elif change.startswith('I'):
        return get_change_number(change)
    else:
        if change in ('latest', 'last'):
            change = 'HEAD'
        change_id = get_change_id(change)
        return get_change_number(change_id)


def qualify_node_list(string_list, default_suffix='.eqiad.wmnet'):
    """Qualify any unqualified nodes in a comma-separated list by appending a
    default domain suffix."""
    return ','.join(node if '.' in node else node + default_suffix
                    for node in string_list.split(','))


class Parser(argparse.ArgumentParser):
    def format_help(self):
        return textwrap.dedent(__doc__).lstrip()


ap = Parser(description='Puppet catalog compiler')
ap.add_argument('change', help='Gerrit change number.', type=get_change)
ap.add_argument('nodes', type=qualify_node_list,
                help='Comma-separated list of nodes.')
ap.add_argument('--api-token', default=os.environ.get('JENKINS_API_TOKEN'),
                help='Jenkins API token. Defaults to JENKINS_API_TOKEN.')
ap.add_argument('--username', default=os.environ.get('JENKINS_USERNAME'),
                help='Jenkins user name. Defaults to JENKINS_USERNAME.')
ap.add_argument('--future', action='store_true',
                help='Check compilation against the future parser as well.')
args = ap.parse_args()

if not args.api_token or not args.username:
    sys.exit('You must either provide the --api-token and --username options'
             ' or define JENKINS_API_TOKEN and JENKINS_USERNAME in your env.')

jenkins = jenkinsapi.jenkins.Jenkins(
    baseurl=JENKINS_URL,
    username=args.username,
    password=args.api_token
)

print(yellow('Compiling %(change)s on node(s) %(nodes)s...' % vars(args)))

job = jenkins.get_job('operations-puppet-catalog-compiler')
build_params = {
    'GERRIT_CHANGE_NUMBER': str(args.change),
    'LIST_OF_NODES': args.nodes,
}

if args.future:
    build_params['COMPILER_MODE'] = 'change,future'

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
    print(format_console_output(new_output[len(output):]),)
    output = new_output

# Puppet's exit code is not always meaningful, so we grep the output
# for failures before declaring victory.
ok = ('Run finished' in output and not
      re.search(r'[1-9]\d* (ERROR|FAIL)', output))
if ok:
    print(green('SUCCESS'))
    sys.exit(0)
else:
    print(red('FAIL'))
    sys.exit(1)
