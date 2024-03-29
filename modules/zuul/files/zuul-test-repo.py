#!/usr/bin/env python3
"""Easily trigger zuul pipelines for a Gerrit repository."""
# Copyright 2015, 2021 Kunal Mehta <legoktm@debian.org>
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

if repo.startswith('ext:'):
    # Allow "ext:MassMessage" as shorthand
    repos = ['mediawiki/extensions/' + repo.split(':', 1)[1]]
elif repo.startswith('file:'):
    # Or entire files with "file:/home/foobar/list"
    with open(repo.split(':', 1)[1]) as f:
        repos = f.read().splitlines()
else:
    repos = [repo]


def test_repo(repo, pipeline):
    # Fetch the latest change for the repo from the Gerrit API
    r = requests.get('https://gerrit.wikimedia.org/r/changes/?'
                     'q=status:merged+project:%s&n=1&o=CURRENT_REVISION'
                     % repo)
    data = json.loads(r.text[4:])
    if not data:
        print('Error, could not find any changes in %s.' % repo)
        sys.exit(1)
    change = data[0]
    change_number = change['_number']
    patchset = change['revisions'][change['current_revision']]['_number']
    print(f'Going to test {repo}@{change_number},{patchset}')
    subprocess.call(['zuul', 'enqueue',
                     '--trigger', 'gerrit',
                     '--pipeline', pipeline,
                     '--project', repo,
                     '--change', f'{change_number},{patchset}'])


if __name__ == '__main__':
    for repo in repos:
        test_repo(repo, pipeline)
