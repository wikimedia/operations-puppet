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
import argparse
import datetime
import json
import logging
import os
import sys
import textwrap
import time

import requests

from git import Repo, GitCommandError
from phabricator import Phabricator

PUPPET_DIR = '/var/lib/git/operations/puppet'
GIT = Repo(PUPPET_DIR).git

GERRIT_URL = 'https://gerrit.wikimedia.org/r'

GERRIT_API = os.path.join(
    GERRIT_URL,
    'changes',
    'operations%2Fpuppet~production~{}'
)


class GerritAPIError(Exception):
    """Exception class for gerrit api."""

    pass


class PhabTasks(object):
    """Check and poke phab tasks."""

    # Days without activity
    INACTIVE_DAYS = 30

    # Comment to leave on inactive tasks
    COMMENT = textwrap.dedent('''
    This task hasn't had an update in {inactive_days} days and has a
    patch that is cherry-picked on deployment-puppetmaster:

    > {commit}
    ''')

    def __init__(self, client, tasks):
        """
        Initialzie phab task object.

        :param client: Phabricator object
        :param tasks: Dict containing task ids and sha1s
        """
        self.client = client
        self.tasks = tasks
        self._inactive_tasks = {}
        self._response = {}

    @property
    def task_info(self):
        """Wrap maniphest.info response."""
        if not self._response:
            self._response = self.client.maniphest.query(ids=self.tasks.keys())

        return self._response

    @property
    def inactive_tasks(self):
        """Get tasks that have no seen activity in a while."""
        if self._inactive_tasks:
            return self._inactive_tasks

        inactive_days_in_seconds = datetime.timedelta(
            days=self.INACTIVE_DAYS).total_seconds()

        active_threshold = int(time.time() - inactive_days_in_seconds)

        for task in self.task_info.response.keys():
            task = self.task_info[task]
            too_old = int(task.get('dateModified', 0)) < active_threshold
            task_id = task['id']

            if too_old:
                logging.debug(
                    'Task %s has not had activity in %s days',
                    task_id,
                    self.INACTIVE_DAYS)

                self._inactive_tasks[task_id] = self.tasks[int(task_id)]

        return self._inactive_tasks

    def poke_inactive(self):
        """Find inactive tasks and comment on them."""
        for task, sha1 in self.inactive_tasks.iteritems():
            quoted_commit = '\n> '.join(get_commit_msg(sha1).splitlines())
            msg = self.COMMENT.format(
                commit=quoted_commit, inactive_days=self.INACTIVE_DAYS)

            logging.debug('Posting a message to T%s: %s', task, msg)
            self.client.maniphest.update(id=task, comments=msg)


def get_phab_client():
    """Return a Phabricator client instance."""
    with open('/root/beta-puppetmaster.arcrc') as arcrc:
        config_json = json.loads(arcrc.read())

    host = config_json['hosts'].keys()[0]
    token = config_json['hosts'][host]['token']

    return Phabricator(host=host, token=token)


def git_log(fmt='%H', commit_range='@{u}..HEAD'):
    """Return formatted git log."""
    return GIT.log('--format={}'.format(fmt), '{}'.format(commit_range))


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
    try:
        logging.info('Removing: %s', sha1)
        GIT.rebase('--onto', '{}^'.format(sha1), sha1)
    except GitCommandError:
        GIT.rebase('--abort')
        logging.error('Failed to remove patch %s', sha1)
        return


def get_patches():
    """Return list of cherry-picked SHA1s."""
    return git_log().splitlines()


def setup_logging(args):
    """
    Setup logging for script.

    :params args: argument parser namespace
    """
    level = logging.INFO
    if args.verbose:
        level = logging.DEBUG

    logger = logging.getLogger()
    logger.setLevel(level)

    if sys.stdout.isatty():
        tty_handle = logging.StreamHandler()
        logger.addHandler(tty_handle)
    else:
        file_handle = logging.FileHandler(args.output_file)
        logger.addHandler(file_handle)

    # Silence noisy logger
    logging.getLogger(
        'requests.packages.urllib3.connectionpool').setLevel(logging.WARNING)


def parse_args():
    """Parse script args."""
    ap = argparse.ArgumentParser()
    ap.add_argument(
        '-v', '--verbose', action='store_true',
        help='Increase output verbosity')
    ap.add_argument(
        '-o', '--output-file',
        default='/var/log/git-clean-puppetmaster.log',
        help='Output log file path')

    return ap.parse_args()


def main():
    """Run script."""
    setup_logging(parse_args())

    patches = get_patches()
    tasks = {}
    for patch in patches:
        change = get_change_id(patch)

        if change and is_active(change):
            logging.debug('Patch %s is active', patch)
            task_id = get_task_id(patch)

            if task_id:
                logging.debug('Patch %s has task id %s', patch, task_id)
                tasks[task_id] = patch

        else:
            tasks.pop(patch, None)
            remove_commit(patch)

    phab_tasks = PhabTasks(get_phab_client(), tasks)
    phab_tasks.poke_inactive()

if __name__ == '__main__':
    sys.exit(main())
