#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0

import argparse
import subprocess
import sys

from pathlib import Path


def rev_count(basedir: Path, remote: str, branch: str) -> tuple[int, int]:
    """Return number of revisions our branch is ahead and behind

    Args:
        basedir (Path): Path to checkout of repository
        remote (str): Git remote
        branch (str): Remote branch

    Returns:
        Union[int, int]: Number of revisions behind, number of revision ahead
    """
    return (
        int(subprocess.run([
            'git',
            '-C',
            basedir,
            'rev-list',
            '--count',
            f'{remote}/{branch}..HEAD'
        ], check=True, stdout=subprocess.PIPE).stdout),
        int(subprocess.run([
            'git',
            '-C',
            basedir,
            'rev-list',
            '--count',
            f'HEAD..{remote}/{branch}'
        ], check=True, stdout=subprocess.PIPE).stdout))


def format_prometheus_output(name: str, ahead: int, behind: int) -> str:
    """Format data in Prometheus metrics format

    Args:
        name (str): Repository name
        ahead (int): Number of commits that local checkout is ahead of origin
        behind (int): Number of commits that localcheckout is behind origin

    Returns:
        str: Metrics in Prometheus compatible text format
    """

    return f"""# HELP puppetmaster_commits_ahead checkout is X number of commits ahead the remote.
# TYPE puppetmaster_commits_ahead gauge
puppetmaster_commits_ahead{{repository="{name}"}} {ahead}
# HELP puppetmaster_commits_behind checkout is X number of commits behind the remote.
# TYPE puppetmaster_commits_behind gauge
puppetmaster_commits_behind{{repository="{name}"}} {behind}
"""


if __name__ == '__main__':
    parser = argparse.ArgumentParser(
        prog='check_git_needs_merge',
        description="""Exporters Prometheus metric to determine if there \
is outstanding changes which needs to be merged on a Puppet master""",
    )

    parser.add_argument('--basedir', type=Path, help='Path to checkout', required=True)
    parser.add_argument('--remote', type=str, default='origin', help='Git remote')
    parser.add_argument('--branch', type=str, default='production', help="branch")
    parser.add_argument('--dir',
                        type=Path,
                        default='/var/lib/promentheus/node.d/',
                        help='Output path for prom file')
    parser.add_argument('--name',
                        type=str,
                        default='puppet',
                        help='Short-hand, human-readable, name for the repository')
    args = parser.parse_args()

    if not args.basedir.is_dir():
        print(f"Provided basedir, {args.basedir} is not a directory")
        sys.exit(1)

    if not args.dir.is_dir():
        print(f'The directory ({args.dir}) does not exist')
        sys.exit(1)

    output = args.dir / f'puppetmerge_{args.name}.prom'
    ahead, behind = rev_count(args.basedir, args.remote, args.branch)
    output.write_text(format_prometheus_output(args.name, ahead, behind))
