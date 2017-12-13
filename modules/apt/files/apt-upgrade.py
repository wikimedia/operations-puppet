#!/usr/bin/env python3

import argparse
import os
import subprocess
import sys
import apt
import shlex

# Common usage:
#   'apt-upgrade stretch-security        upgrade packages from stretch-security
#   'apt-upgrade stretch-security -s     like above, but simulating operations
#   'apt-upgrade stretch-security -v     like above, but being verbose
#


def print_verbose(verbose, msg):
    if verbose:
        print(msg)


def print_verbose_pkg(verbose, pkg):
    msg = pkg.name
    msg += " "
    msg += pkg._pkg.current_ver.ver_str
    msg += " --> "
    msg += pkg.candidate.version
    print_verbose(verbose, msg)


def upgrade(verbose, simulate, pkgs_to_upgrade):
    # we could use python-apt for this as well, except that it does not
    # behaves as one would expect when it comes to deps resolving and
    # pinning/holds treatment. Instead of writting a lot of complex code for
    # that just use this command directly.
    cmd = "DEBIAN_FRONTEND=noninteractive apt-get install"
    cmd += " -q -y"

    if simulate:
        cmd += " -s"

    for pkg in pkgs_to_upgrade:
        cmd += " "
        cmd += shlex.quote(pkg)

    # another benefit: the concrete CMDLINE used here can be reported (-v), so
    # this can be reproduced easily, the behavior is more understandable and
    # there is a great error reporting from apt-get in case of pkg/deps
    # conflicts or other internal error.
    print_verbose(verbose, "")
    print_verbose(verbose, cmd)
    ret = subprocess.call(cmd, shell=True)
    return ret


def pkg_is_candidate(verbose, src, pkg):
    if not pkg.is_upgradable:
        return False

    origin = pkg.candidate.origins[0]
    if origin.archive != src:
        return False

    print_verbose_pkg(verbose, pkg)
    return True


def run(src, simulate, verbose):
    cache = apt.Cache()
    cache.update()
    cache.open(None)

    pkgs_to_upgrade = []
    for name in cache.keys():
        pkg = cache[name]
        if pkg_is_candidate(verbose, src, pkg):
            pkgs_to_upgrade.append(name)

    cache.close()
    if len(pkgs_to_upgrade) == 0:
        print_verbose(verbose, "No packages found to upgrade from " + src)
        return 0

    return upgrade(verbose, simulate, pkgs_to_upgrade)


def main():
    parser = argparse.ArgumentParser(description="Run a targetted upgrade of packages")
    parser.add_argument('-v', action='store_true', help="be verbose")
    parser.add_argument('-s', action='store_true',
                        help="simulate operations, pass '-s' to `apt-get install`")
    parser.add_argument('argument',
                        help="Main argument: source repository to upgrade from")
    args = parser.parse_args()

    if os.geteuid() != 0:
        print("E: root needed")
        sys.exit(1)

    ret = run(args.argument, args.s, args.v)
    sys.exit(ret)


if __name__ == "__main__":
    main()
