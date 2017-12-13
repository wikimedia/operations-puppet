#!/usr/bin/env python3

import argparse
import subprocess
import sys
import tempfile

#
# This script is a wrapper for 'apt-get update' and 'apt-get upgrade'
# to easily update/upgrade packages from a given repository.
#
# Common usage:
#   'apt-upgrade list'                   list available repositories
#   'apt-upgrade stretch-security        upgrade packages from stretch-security
#   'apt-upgrade stretch-security -s     like above, but simulating operations
#   'apt-upgrade stretch-security -v     like above, but being verbose
#
# To add support for more repositories, you need 2 things: the 'deb' line
# and the preferences for priorities (which can be left blanck using 'NA').
# Write a 'register_xxx()' function like the others and call it from the
# register_all() function. You should now be able to see this using the
# 'list' command.
#


def register_all():
    register_stretchsecurity()
    register_stretchbackports()
    register_stretch()
    register_stretchupdates()
    register_stretchwikimedia()


def register_stretchsecurity():
    name = "stretch-security"
    repo = """
deb http://security.debian.org stretch/updates main contrib non-free
deb http://deb.debian.org/debian/ stretch main contrib non-free
"""
    pref = """
Package: *
Pin: release l=Debian-Security
Pin-Priority: 990

Package: *
Pin: release l=Debian
Pin-Priority: 99
"""
    register_info(name, repo, pref)


def register_stretchbackports():
    name = "stretch-backports"
    repo = """
deb http://deb.debian.org/debian/ stretch-backports main contrib non-free
"""
    pref = "NA"
    register_info(name, repo, pref)


def register_stretch():
    name = "stretch"
    repo = """
deb http://deb.debian.org/debian/ stretch main contrib non-free
"""
    pref = """
Package: *
Pin: release l=Debian
Pin-Priority: 500
"""
    register_info(name, repo, pref)


def register_stretchupdates():
    name = "stretch-updates"
    repo = """
deb http://deb.debian.org/debian/ stretch-updates main contrib non-free
"""
    pref = """
Package: *
Pin: release l=Debian
Pin-Priority: 500
"""
    register_info(name, repo, pref)


def register_stretchwikimedia():
    name = "stretch-wikimedia"
    repo = """
deb http://apt.wikimedia.org/wikimedia stretch-wikimedia main contrib non-free
"""
    pref = """
Package: *
Pin: release l=Wikimedia
Pin-Priority: 1001
"""
    register_info(name, repo, pref)


InfoRegister = {}


class Info:
    """ class to represent a repository information """
    def __init__(self, repo, pref):
        self.repo = repo
        self.pref = pref


def register_info(name, repo, pref):
    """ register a new repository into memory """
    InfoRegister[name] = Info(repo, pref)


def print_info(info, name):
    """ pretty print the information about a repository """
    print("--- " + name + ":")
    print(info.repo)
    print(info.pref)


def tmp_file(content):
    """ generate a tempfile with a given content """
    if content == "NA":
        return open("/dev/null")
    tmp_file = tempfile.NamedTemporaryFile(mode='r+', encoding='utf-8')
    tmp_file.write(content)
    # FIXME: Why is this needed? probably a caching issue, the file
    # doesn't have the content written unless using this read() ?
    tmp_file.read()
    return tmp_file


def exec_cmd(cmd, verbose):
    """ execute a given command into the system shell """
    if verbose:
        print("")
        print(cmd)
        print("")
    ret = subprocess.call(cmd, shell=True)
    if ret != 0:
        print("E: something failed", file=sys.stderr)
        sys.exit(ret)


def generate_args(repo_file, pref_file):
    """ generate arguments for apt-get """
    args = " -o Dir::Etc::SourceList=" + repo_file
    args = args + " -o Dir::Etc::Preferences=" + pref_file
    args = args + " -o Dir::Etc::SourceParts=/dev/null"
    args = args + " -q -y"
    args = args + " -o Dpkg::Options::='--force-confdef'"
    args = args + " -o Dpkg::Options::='--force-confold'"
    return args


def exec_apt_update(args, verbose):
    """ execute apt-get update """
    cmd = "DEBIAN_FRONTEND=noninteractive apt-get update" + args
    exec_cmd(cmd, verbose)


def exec_apt_upgrade(args, verbose):
    """ execute apt-get upgrade """
    cmd = "DEBIAN_FRONTEND=noninteractive apt-get upgrade" + args
    exec_cmd(cmd, verbose)


def run(name, verbose, simulate):
    """ main run function, generate tmp files and run apt-get """
    info = InfoRegister[name]

    if verbose:
        print_info(info, name)

    repo_file = tmp_file(info.repo)
    pref_file = tmp_file(info.pref)

    args = generate_args(repo_file.name, pref_file.name)

    exec_apt_update(args, verbose)

    if simulate:
        args = args + " -s"

    exec_apt_upgrade(args, verbose)

    repo_file.close()
    pref_file.close()


def list_registers():
    """ pretty print the list of repositories """
    for name in InfoRegister:
        print_info(InfoRegister[name], name)


def main():
    parser = argparse.ArgumentParser(description="Run a targetted upgrade of packages")
    parser.add_argument('-v', action='store_true', help="be verbose")
    parser.add_argument('-s', action='store_true',
                        help="simulate operations, pass '-s' to `apt-get upgrade`")
    parser.add_argument('argument',
                        help="Main argument. Use 'list' to list possible "
                             "targets, or a given target source repository / "
                             "channel to upgrade from")
    args = parser.parse_args()

    register_all()

    if args.argument == "list":
        list_registers()
        sys.exit(0)

    for name in InfoRegister:
        if name == args.argument:
            run(name, args.v, args.s)
            sys.exit(0)

    print("I don't know how to handle this argument: " + args.argument, file=sys.stderr)
    print("Use 'list' to know the repos this script can run with", file=sys.stderr)
    sys.exit(1)


if __name__ == "__main__":
    main()
