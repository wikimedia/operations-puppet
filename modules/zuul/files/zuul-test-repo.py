#!/usr/bin/env python2
"""Easily trigger zuul pipelines for a Gerrit repository."""
# Copyright 2015 Legoktm
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.

from __future__ import print_function

import json
import requests
import subprocess
import sys

if len(sys.argv) < 2:
    print('Usage: zuul-test-repo repository [pipeline]')
    sys.exit(1)

repo = sys.argv[1]
try:
    pipeline = sys.argv[2]
except IndexError:
    pipeline = 'test'

# Allow "ext:MassMessage" as shorthand
if repo.startswith('ext:'):
    repo = 'mediawiki/extensions/' + repo.split(':', 1)[1]

# Fetch the latest change for the repo from the Gerrit API
r = requests.get('https://gerrit.wikimedia.org/r/changes/?'
                 'q=status:merged+project:%s&n=1&o=CURRENT_REVISION' % repo)
data = json.loads(r.text[4:])
if not data:
    print('Error, could not find any changes in %s.' % repo)
    sys.exit(1)
change = data[0]
change_number = change['_number']
patchset = change['revisions'][change['current_revision']]['_number']
print('Going to test %s@%s,%s' % (repo, change_number, patchset))
subprocess.call(['zuul', 'enqueue',
                 '--trigger', 'gerrit',
                 '--pipeline', pipeline,
                 '--project', repo,
                 '--change', '%s,%s' % (change_number, patchset)])
