#!/usr/bin/env python3

import argparse
import os
import sys
import apt
import apt_pkg

# Common usage:
#   'apt-upgrade stretch-security        upgrade packages from stretch-security
#   'apt-upgrade stretch-security -s     like above, but simulating operations
#   'apt-upgrade stretch-security -v     like above, but being verbose
#
# make sure you hold+pin beforehand those packages that should not be upgraded


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
    name = pkg.name
    orig = pkg.installed.version
    if pkg.marked_delete:
        dest = "remove"
    else:
        dest = pkg.candidate.version
    print_verbose(verbose, '{} {} --> {}'.format(name, orig, dest))


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
    except apt_pkg.Error as e:
        print_verbose(verbose, '{} not for upgrade: {}'.format(pkg.name, str(e)))
        pkg.mark_keep()
        marked_upgrade = False

    return marked_upgrade


class AptFilter(apt.cache.Filter):
    """ filter for python-apt cache to filter only packages upgradable from a
    specific source.
    """

    def __init__(self, src):
        super().__init__()
        self.src = src

    def apply(self, pkg):
        """ filtering function
        :param pkg: Package
        """
        if pkg.is_installed and pkg.is_upgradable and pkg.candidate.origins[0].archive == self.src:
            return True

        return False


def run(src, simulate, verbose):
    """ run the cache update, calculate upgrades and commit them
    :param src: str
    :param simulate: boolean
    :param verbose: boolean
    """
    cache = apt.cache.FilteredCache()
    print_verbose(verbose, "Updating cache ...")
    cache.update()
    cache.open(None)
    cache.set_filter(AptFilter(src))

    pkgs_to_upgrade = False
    for pkg_name in cache.keys():
            pkgs_to_upgrade += pkg_upgrade(verbose, cache[pkg_name])

    if not pkgs_to_upgrade:
        print_verbose(verbose, 'No packages found to upgrade from {}'.format(src))
        return

    # report what we will be doing
    for pkg in cache.get_changes():
        print_verbose_pkg(verbose, pkg)

    if not simulate:
        cache.commit()
    else:
        print_verbose(verbose, "Simulate, not performing changes")

    cache.close()


def main():
    parser = argparse.ArgumentParser(description="Run a targeted upgrade of packages")
    parser.add_argument('-v', action='store_true', help="be verbose")
    parser.add_argument('-s', action='store_true',
                        help="simulate operations")
    parser.add_argument('source',
                        help="Main argument: source repository to upgrade from")
    args = parser.parse_args()

    if os.geteuid() != 0:
        sys.exit("root needed")

    run(args.source, args.s, args.v)


if __name__ == "__main__":
    main()
