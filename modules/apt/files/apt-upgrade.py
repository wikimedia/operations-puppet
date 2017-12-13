#!/usr/bin/env python3

import argparse
import os
import sys
import apt

# Common usage:
#   'apt-upgrade stretch-security        upgrade packages from stretch-security
#   'apt-upgrade stretch-security -s     like above, but simulating operations
#   'apt-upgrade stretch-security -v     like above, but being verbose
#
# make sure you hold+pinn beforehand those packages that should not be upgraded


def print_verbose(verbose, msg):
    """ print information if verbose
    :param verbose: boolean
    :param msg: str
    """
    if verbose:
        print(msg)


def print_verbose_pkg(verbose, pkg):
    """ print information about a package
    :param verbose: boolean
    :param pkg: Package
    """
    if not verbose:
        return
    msg = pkg.name
    msg += " "
    msg += pkg._pkg.current_ver.ver_str
    msg += " --> "
    if pkg.marked_delete:
        msg += "remove"
    else:
        msg += pkg.candidate.version
    print_verbose(verbose, msg)


def pkg_is_candidate(src, pkg):
    """ check if a package is a valid candidate for upgrade
    :param src: str
    :param pkg: Package
    """
    if not pkg.is_upgradable:
        return False

    origin = pkg.candidate.origins[0]
    if origin.archive != src:
        return False

    return True


def pkg_upgrade(verbose, pkg):
    """ try to mark a package for upgrade
    :param verbose: boolean
    :param pkg: Package
    """
    if not pkg.is_installed:
        return False
    try:
        pkg.mark_upgrade()
        marked_upgrade = True
    except Exception as e:
        print_verbose(verbose, pkg.name + " not for upgrade: " + str(e))
        pkg.mark_keep()
        marked_upgrade = False
        pass

    return marked_upgrade


def run(src, simulate, verbose):
    """ run the cache update, calculate upgrades and commit them
    :param src: str
    :param simulate: boolean
    :param verbose: boolean
    """
    ret = 0
    cache = apt.Cache()
    print_verbose(verbose, "Updating cache ...")
    cache.update()
    cache.open(None)

    pkgs_to_upgrade = False
    for name in cache.keys():
        pkg = cache[name]
        if pkg_is_candidate(src, pkg):
            pkgs_to_upgrade += pkg_upgrade(verbose, pkg)

    if not pkgs_to_upgrade:
        print_verbose(verbose, "No packages found to upgrade from " + src)
        return ret

    # report what we will be doing
    for pkg in cache.get_changes():
        print_verbose_pkg(verbose, pkg)

    if not simulate:
        try:
            cache.commit()
        except Exception as e:
            print_verbose(verbose, "Error during cache commit: " + str(e))
            ret = 1
            pass
    else:
        print_verbose(verbose, "Simulate, not performing changes")

    cache.close()
    return ret


def main():
    parser = argparse.ArgumentParser(description="Run a targetted upgrade of packages")
    parser.add_argument('-v', action='store_true', help="be verbose")
    parser.add_argument('-s', action='store_true',
                        help="simulate operations, pass '-s'")
    parser.add_argument('argument',
                        help="Main argument: source repository to upgrade from")
    args = parser.parse_args()

    if os.geteuid() != 0:
        print("E: root needed", file=sys.stderr)
        sys.exit(1)

    ret = run(args.argument, args.s, args.v)
    sys.exit(ret)


if __name__ == "__main__":
    main()
