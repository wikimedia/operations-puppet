#!/usr/bin/env python

from __future__ import print_function
import argparse
import subprocess
import sys
import re

#
# This script is a wrapper for 'apt-get update' and 'apt-get upgrade'
# to easily update/upgrade packages from a given repository.
#
# Common usage:
#   'apt-upgrade stretch-security        upgrade packages from stretch-security
#   'apt-upgrade stretch-security -s     like above, but simulating operations
#   'apt-upgrade stretch-security -v     like above, but being verbose
#
# Yes, all this could be done in two lines with bash, but hey ...


def exec_cmd(cmd, verbose):
    """ execute a given command into the system shell """
    if verbose:
        print(cmd)
        print("")
    else:
        cmd = cmd + ">/dev/null"
    ret = subprocess.call(cmd, shell=True)
    if ret != 0:
        print("E: something failed", file=sys.stderr)
        sys.exit(ret)


def generate_args(extra_args):
    """ generate arguments for apt-get """
    args = " -q -y"
    args = args + " -o Dpkg::Options::='--force-confdef'"
    args = args + " -o Dpkg::Options::='--force-confold'"
    args = args + extra_args
    return args


def exec_apt_update(args, verbose):
    """ execute apt-get update """
    cmd = "DEBIAN_FRONTEND=noninteractive apt-get update" + args
    exec_cmd(cmd, verbose)


def exec_apt_install(args, verbose):
    """ execute apt-get install """
    cmd = "DEBIAN_FRONTEND=noninteractive apt-get install" + args
    exec_cmd(cmd, verbose)


def get_pkgs(src):
    """ calculate packages to upgrade """
    output = subprocess.check_output("apt-show-versions", shell=True)
    # each line has this format:
    # evince:amd64/testing 3.26.0-1 upgradeable to 3.26.0-2'
    regex = ".*/" + src + ".*upgradeable.*"
    upgradeable_lines = re.findall(regex, output)

    pkgs = ""
    for line in upgradeable_lines:
        pkgs = pkgs + " " + line.split(":")[0]

    return pkgs


def run(src, simulate, verbose):
    """ update cache, calculate packages, upgrade them """
    exec_apt_update(generate_args(""), verbose)
    pkgs = get_pkgs(src)
    if len(pkgs) == 0:
        if verbose:
            print("W: no upgradeable packages from " + src)
        sys.exit(0)

    if simulate:
        args = generate_args(" -s" + pkgs)
    else:
        args = generate_args(pkgs)

    exec_apt_install(args, verbose)


def main():
    parser = argparse.ArgumentParser(description="Run a targetted upgrade of packages")
    parser.add_argument('-v', action='store_true', help="be verbose")
    parser.add_argument('-s', action='store_true',
                        help="simulate operations, pass '-s' to `apt-get upgrade`")
    parser.add_argument('argument',
                        help="Main argument: source repository to upgrade from")
    args = parser.parse_args()

    run(args.argument, args.s, args.v)
    sys.exit(0)


if __name__ == "__main__":
    main()
