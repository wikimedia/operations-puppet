#!/usr/bin/env python3
"""example script"""

import json
import itertools
import logging
import shlex

from argparse import ArgumentParser
from collections import defaultdict
from pathlib import Path
from subprocess import run


TEST_SQL = """
SELECT
    files.path,
    blame.line_no,
    commits.hash,
    commits.author_email
FROM files, blame('', '', files.path)
JOIN commits ON commits.hash = blame.commit_hash
WHERE path LIKE 'modules/acme_chief/%'
"""


def get_args() -> None:
    """Parse arguments.

    Returns:
        `argparse.Namespace`: The parsed argparser Namespace
    """
    parser = ArgumentParser(description=__doc__)
    parser.add_argument(
        "-e", "--exclude-committer", help="a SQL pattern of committer emails to exclude"
    )
    parser.add_argument("-v", "--verbose", action="count", default=0)
    parser.add_argument("module", help="The module to audit")
    return parser.parse_args()


def get_log_level(args_level: int) -> int:
    """Convert an integer to a logging log level.

    Arguments:
        args_level (int): The log level as an integer

    Returns:
        int: the logging loglevel
    """
    return {
        0: logging.ERROR,
        1: logging.WARN,
        2: logging.INFO,
        3: logging.DEBUG,
    }.get(args_level, logging.DEBUG)


def get_sql_all(excluded_committer):
    """Build SQL string"""
    if excluded_committer:
        email_constraint = f"AND commits.author_email NOT LIKE '%{excluded_committer}'"
    else:
        email_constraint = ""

    sql_str = f"""
    SELECT files.path, blame.line_no, commits.hash, commits.author_email
    FROM files, blame('', '', files.path)
    JOIN commits ON commits.hash = blame.commit_hash
    WHERE path LIKE 'modules/%'
    {email_constraint}"""
    logging.debug("Generated SQL: %s", sql_str)
    return sql_str


def get_sql_module(module, excluded_committer):
    """Build SQL string"""
    if excluded_committer:
        email_constraint = f"AND commits.author_email NOT LIKE '%{excluded_committer}'"
    else:
        email_constraint = ""

    sql_str = f"""
    SELECT files.path, blame.line_no, commits.hash, commits.author_email
    FROM files, blame('', '', files.path)
    JOIN commits ON commits.hash = blame.commit_hash
    WHERE path LIKE 'modules/{module}/%'
    {email_constraint}"""
    logging.debug("Generated SQL: %s", sql_str)
    return sql_str


def pretty_ranges(i):
    """print a nicerlist of numbers"""
    string = []
    for _, num in itertools.groupby(enumerate(i), lambda pair: pair[1] - pair[0]):
        num = list(num)
        if num[0][1] == num[-1][1]:
            string.append(str(num[0][1]))
        else:
            string.append(f'{num[0][1]}-{num[-1][1]}')
    return ','.join(string)


def mergestat(sql):
    """Run mergestat"""
    repo_root = Path(__file__).parent.parent.resolve()
    command = f'mergestat --repo {repo_root} --format json "{sql}"'
    logging.debug('run command: %s', command)
    complete_proc = run(shlex.split(command), capture_output=True, check=True)
    print(complete_proc.stdout)
    return json.loads(complete_proc.stdout)


def process_data(data):
    """Process the results from mergestat"""
    # We should probably create a better data structure for this
    commiters = defaultdict(lambda: defaultdict(lambda: defaultdict(list)))
    for blame_line in data:
        email, sha, line_no, path = blame_line.values()
        commiters[email][sha][path].append(line_no)
    return commiters


def main() -> int:
    """Main entry point.

    Returns:
        int: an int representing the exit code
    """
    args = get_args()
    logging.basicConfig(level=get_log_level(args.verbose))

    # data = mergestat(get_sql_all(args.exclude_committer))
    # data = mergestat(TEST_SQL)
    data = mergestat(get_sql_module(args.module, args.exclude_committer))
    commiters = process_data(data)
    for commiter, commits in commiters.items():
        print(f'{commiter}:')
        print('-'*20)
        for sha, files in commits.items():
            print(f'{sha}:')
            for commitfile, lines in files.items():
                print(f"\t{commitfile}: {pretty_ranges(lines)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
