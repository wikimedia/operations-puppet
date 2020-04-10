#!/bin/env python3
"""
check_git_local_changes.py: Return nagios status code based on the existence and age of
untracked files, uncommited changes and unstaged changes in specified git repository
"""

import argparse
import math
import os
import os.path
import time
import subprocess
import sys

STATUS_OK = 0
STATUS_WARNING = 1
STATUS_CRITICAL = 2
STATUS_UNKNOWN = 3
STATUS_NAMES = {
    STATUS_OK: "OK",
    STATUS_WARNING: "WARNING",
    STATUS_CRITICAL: "CRITICAL",
    STATUS_UNKNOWN: "UNKNOWN",
}


def parse_args():
    """Setup command line argument parser and return parsed args.

    Returns:
        :obj:`argparse.Namespace`: The resulting parsed arguments.

    """
    parser = argparse.ArgumentParser()

    parser.add_argument("gitpath", help="Path to check.")
    parser.add_argument(
        "-a",
        "--age",
        help=("The maximum age in seconds for any of the untracked files before alerting (0 for any"
              "age)."),
        default=0,
        type=int
    )
    args = parser.parse_args()
    return args


def print_status(status, message):
    """Print status in coherent format, and return status value."""
    print(f"git_local_changes: {message} {STATUS_NAMES[status]}")
    return status


def main():
    """Main routine.

    * check if repository exists and is a repository and return critical if not
    * check if there are untracked files and return critical appropriate
    * else check if there are unstaged changes
    * else check if there are uncommited changes

    Returns:
        int: The Nagios status code result.

    """
    args = parse_args()

    if not os.path.isdir(args.gitpath):
        return print_status(STATUS_CRITICAL, f"{args.gitpath} does not exist.")
    os.chdir(args.gitpath)

    if (subprocess.check_output(["git",
                                 "rev-parse",
                                 "--is-inside-work-tree"], shell=False).strip() == b"false"):
        return print_status(STATUS_CRITICAL, f"{args.gitpath} is not a git repository.")

    # check for untracked files
    res = subprocess.check_output(["git",
                                   "ls-files",
                                   "--exclude-standard",
                                   "--others"], shell=False)
    rtime = time.time()
    if res:
        untracked_files = res.decode("utf-8").strip().split("\n")
        message = f"{args.gitpath} contains untracked file(s): {' '.join(untracked_files)}"
        if (args.age == 0):
            return print_status(STATUS_CRITICAL, message)
        else:
            untracked_messages = []
            for untracked in untracked_files:
                untracked_age = rtime - os.stat(untracked).st_mtime
                if untracked_age > args.age:
                    untracked_messages.append(f"{untracked}({math.floor(untracked_age)} seconds)")
            if untracked_messages:
                return print_status(STATUS_CRITICAL, (f"{args.gitpath} contains untracked file(s): "
                                                      f"{' '.join(untracked_messages)}"))

        return print_status(STATUS_WARNING, message)

    # else check for unstaged changes
    if (subprocess.call(["git", "diff-files", "--quiet", "--ignore-submodules"]) != 0):
        return print_status(STATUS_CRITICAL, f"{args.gitpath} contains unstaged changes")

    # else check for uncommitted changes
    if (subprocess.call(["git",
                         "diff-index",
                         "--cached",
                         "--quiet",
                         "--ignore-submodules",
                         "HEAD",
                         "--"]) != 0):
        return print_status(STATUS_CRITICAL,
                            f"{args.gitpath} contains staged but uncommitted changes")

    # else good
    return print_status(STATUS_OK,
                        (f"{args.gitpath} contains no sufficiently old untracked files, unstaged or"
                         "uncommited changes"))


if __name__ == "__main__":
    try:
        sys.exit(main())
    except Exception as ex:
        print("Unexpected exception occurred during check: %s", ex)
        sys.exit(STATUS_UNKNOWN)
