#!/usr/bin/env python3
"""
Fetches changes from origin and shows diffs between HEAD
and FETCH_HEAD

If the changes are acceptable, HEAD will be fast-forwarded
to FETCH_HEAD.

It also runs the conftool merge if necessary.

SHA1 equals HEAD if not specified
"""

import os
import shlex

from argparse import ArgumentParser, RawTextHelpFormatter
from getpass import getuser
from pwd import getpwnam
from subprocess import CalledProcessError, PIPE, run


FILE_PATHS = {
    'ops': {
        'repo': '/var/lib/git/operations/puppet',
        'sha1': '/srv/config-master/puppet-sha1.txt',
    },
    'labsprivate': {
        'repo': '/var/lib/git/labs/private',
        'sha1': '/srv/config-master/labsprivate-sha1.txt',
    }
}

ERROR_MESSAGE = '\033[91m{msg}\033[0m'

"""int: reserved exit code: puppet-merge did not preform a merge operation"""
PUPPET_MERGE_NO_MERGE = 99


def get_args():
    """parse arguments"""
    parser = ArgumentParser(description=__doc__, formatter_class=RawTextHelpFormatter)
    parser.add_argument('-y', '--yes', action='store_true',
                        help='Automatic yes to prompts; assume "yes" as answer to all prompts')
    parser.add_argument('-q', '--quiet', action='store_true', help='Limit output')
    parser.add_argument('-d', '--diffs', action='store_true',
                        help='Only produce diffs do not perform the git merge')
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument('-p', '--labsprivate', action='store_true',
                       help='work on the labs private repo')
    group.add_argument('-o', '--ops', action='store_true', help='work on the ops production repo')
    parser.add_argument('sha1', nargs='?', default='FETCH_HEAD',
                        help='the sha1 commit to merge. Default: %(default)s')
    return parser.parse_args()


def setuid(username):
    """change the process uid to the uid of username"""
    try:
        uid = getpwnam(username).pw_uid
    except KeyError:
        raise SystemExit('unable to get uid for: {}'.format(username))
    try:
        os.setuid(uid)
    except OSError as error:
        raise SystemExit('unable to setuid to : {}\n{}'.format(uid, error))


def git(args, repo_dir, stdout=PIPE):
    """perform a git command"""
    command = shlex.split("git {}".format(args))
    try:
        result = run(command, cwd=repo_dir, stdout=stdout, stderr=PIPE, check=True)
    except CalledProcessError as error:
        raise SystemExit('failed to run `{}`\n{}'.format(' '.join(command), error))
    if isinstance(result.stdout, bytes):
        return result.stdout.decode()
    return result.stdout


def confirm_merge(commiters):
    """ask the user to confirm the merge"""
    confirm = 'yes'
    unique_commiters = set(i for i in commiters if i and i != 'gerrit@wikimedia.org')
    if len(unique_commiters) > 1:
        print('{}: Revision range includes commits from multiple committers!'.format(
            ERROR_MESSAGE.format(msg='WARNING')))
        confirm = 'multiple'
    answer = input('Merge these changes? ({}/no)? '.format(confirm))
    if answer != confirm:
        raise SystemExit("Aborting merge.")


def main():
    """main entry point"""
    git_user = 'gitpuppet'
    running_user = getuser()
    args = get_args()
    config = FILE_PATHS['ops'] if args.ops else FILE_PATHS['labsprivate']

    if running_user != git_user:
        setuid(git_user)

    remote_url = git('config --get remote.origin.url', config['repo'])
    print('Fetching new commits from :{}'.format(remote_url))
    git('fetch', config['repo'])
    head_sha1_old = git('rev-parse HEAD', config['repo'])
    target_sha1 = git('rev-parse {}'.format(args.sha1), config['repo'])
    if head_sha1_old == target_sha1:
        print('No changes to merge.')
        return PUPPET_MERGE_NO_MERGE
    if not args.quiet:
        changes = git('diff --color HEAD..{}'.format(target_sha1), config['repo'])
        print(changes)
    if args.diffs:
        print(target_sha1)
        return 0
    if not args.quiet:
        git('log HEAD..{} --format="%C(bold magenta)%cn%C(reset): %s (%h)"'.format(
            target_sha1),
            config['repo'], None)
    if not args.yes:
        commiters = git('log HEAD..{} --format=%ce'.format(target_sha1), config['repo'])
        confirm_merge(commiters.split('\n'))
    print('HEAD is currently {}'.format(head_sha1_old))
    git('merge --ff-only {}'.format(target_sha1), config['repo'], None)
    print('Running git clean to clean any untracked files.')
    git('clean -dffx -e /private/', config['repo'], None)
    head_sha1_new = git('rev-parse HEAD', config['repo'])
    print('HEAD is now {}'.format(head_sha1_new))
    if os.path.isdir(os.path.dirname(config['sha1'])):
        with open(config['sha1'], 'w') as sha1_fd:
            sha1_fd.write('{}\n'.format(head_sha1_new))
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
