#!/usr/bin/python
# -*- coding: utf-8 -*-
"""
git-clean-puppetmaster
----------------------

This script will veinly attempt to enforce some order onto the patches picked
onto a puppetmaster. It ensures that all patches are not in a MERGED or
ABANDONED state in gerrit. This script will also be annoying and (possibly
repeatedly) poke any tasks associated with any cherry-picked patches.
"""
from __future__ import print_function

import json
import os
import subprocess
import sys
import time

import requests

# One month in seconds
ACTIVE = 30 * 24 * 60 * 60

PUPPET_DIR = '/var/lib/git/operations/puppet'
GIT = '/usr/bin/git'
GIT_CMD = (GIT, '-C', PUPPET_DIR)


GERRIT_URL = 'https://gerrit.wikimedia.org/r'

GERRIT_API = os.path.join(
    GERRIT_URL,
    'changes',
    'operations%2Fpuppet~production~{}'
)


class GerritAPIError(Exception):
    """Exception class for gerrit api."""

    pass


class PhabTask(object):
    """Encapsulate phab task api."""

    URL = 'https://phabricator.wikimedia.org'
    API = os.path.join(URL, 'api')
    API_QUERY = 'maniphest.query'
    API_UPDATE = 'maniphest.update'
    API_DETAIL = 'maniphest.gettasktransactions'

    COMMENT = '''
    This task has a patch that is cherry-picked on deployment-puppetmaster:

    > {commit}
    '''

    """Class to encapsulate arcanist info."""
    def __init__(self, task, sha):
        """Build phab task."""
        self.task = task
        self.sha = sha
        self._token = None
        self._is_active = None
        self._closed = None

    def _api(self, endpoint=None):
        """Return json data from api query."""
        if not endpoint:
            endpoint = self.API_QUERY
        data = {}
        headers = {'accept': 'application/json'}
        data['api.token'] = self.token
        r = requests.post(
            os.path.join(self.API, endpoint),
            headers=headers,
            data=data)

        r.raise_for_status()

        return r.json()

    @property
    def token(self):
        """Get Conduit API token."""
        if self._token:
            return self._token

        with open('/root/beta-puppetmaster.arcrc') as arcrc:
            config_json = json.loads(arcrc.read())

        self._token = config_json['hosts'][self.API + '/']['token']

    @property
    def is_closed(self):
        """Determine if task is closed from task-id."""
        if self._closed is not None:
            return self._closed

        data = {'ids[0]': self.task}
        query_data = self._api(data)
        self._closed = query_data['result'][str(self.task)]['isClosed']

        return self._closed

    @property
    def is_active(self):
        """
        Determine if a task is active or not.

        Currently, "active" is defined as "has seen activity in the past month"
        """
        if self._is_active is not None:
            return self._is_active

        data = {'ids[0]': self.task}
        activities = self._api(
            data, endpoint=self.API_DETAIL)['result'][str(self.task)]

        latest = sorted(
            activities,
            key=lambda x: x['dateCreated'],
            reverse=True)[0]

        one_month_ago = '{:.0f}'.format(time.time() - self.ACTIVE)
        self._is_active = latest['dateCreated'] > one_month_ago
        return self._is_active

    def poke(self, task, commit_hash):
        """Comment on task that there is a cherry-picked patch on beta."""
        quoted_commit = '\n> '.join(get_commit_msg(self.sha).splitlines())
        msg = self.COMMENT.format(commit=quoted_commit)

        data = {
            "id": self.task,
            "comments": msg
        }

        self._api(data, endpoint=self.API_UPDATE)


def git_log(fmt='%H', commit_range='@{u}..HEAD'):
    """Return formatted git log."""
    cmd = list(GIT_CMD) + [
        'log', '--format={}'.format(fmt), '{}'.format(commit_range)]
    return subprocess.check_output(cmd)


def get_commit_msg(commit_hash):
    """Get git commit message from sha1."""
    return git_log(fmt='%B', commit_range='{0}^..{0}'.format(commit_hash))


def get_change_id(commit_hash):
    """Get change-id from git commit message."""
    msg = get_commit_msg(commit_hash)
    for line in msg.splitlines():
        if line.lower().startswith('change-id: '):
            return line[len('change-id: '):]


def is_active(change_id):
    """Determine patch status from change-id."""
    headers = {'accept': 'application/json'}
    r = requests.get(GERRIT_API.format(change_id), headers=headers)
    r.raise_for_status()

    if not r.text[:4] == ")]}'":
        raise GerritAPIError('Missing ")]}\'" prefix for JSON content')

    ret = json.loads(r.text[4:])
    return ret.get('status', 'NEW') not in ['MERGED', 'ABANDONED']


def get_task_id(commit_hash):
    """Get task from git commit message."""
    msg = get_commit_msg(commit_hash)
    for line in msg.splitlines():
        if line.lower().startswith('bug: t'):
            return int(line[len('bug: t'):])


def remove_commit(sha1):
    """Remove commit from repo based on sha1."""
    cmd = list(GIT_CMD)
    cmd += ['rebase', '--onto']
    cmd += ['{}^'.format(sha1), sha1]
    try:
        print(' '.join(cmd))
        subprocess.check_output(cmd)
    except subprocess.CalledProcessError:
        print('Failed!', ' '.join(cmd))
        subprocess.check_output([GIT_CMD, 'rebase', '--abort'])
        return


def get_patches():
    """Return list of cherry-picked SHA1s."""
    return git_log().splitlines()


def main():
    """Run script."""
    patches = get_patches()
    for patch in patches:
        task_id = get_task_id(patch)

        if task_id:
            task = PhabTask(task_id, patch)
            if not task.is_closed and not task.is_active:
                task.poke()

        change = get_change_id(patch)
        if not is_active(change):
            remove_commit(patch)


if __name__ == '__main__':
    sys.exit(main())
