#!/usr/bin/env python3

import argparse
import os
import sys
import apt
import apt_pkg
import subprocess
import re

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
    if pkg.is_installed:
        orig = pkg.installed.version
    else:
        orig = "absent"
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


class AptFilterUpgradeableSrc(apt.cache.Filter):
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

class AptFilterUpgradeable(apt.cache.Filter):
    """ filter for python-apt cache to get only upgradeable packages.
    """

    def __init__(self):
        super().__init__()

    def apply(self, pkg):
        """ filtering function
        :param pkg: Package
        """

        if pkg.is_installed and pkg.is_upgradable:
            return True

        return False


def run_upgrade(cache, src, simulate, verbose):
    """ calculate upgrades and commit them
    :param cache: apt.Cache
    :param src: str
    :param simulate: boolean
    :param verbose: boolean
    """
    cache.set_filter(AptFilterUpgradeableSrc(src))

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


def run_upgrade_report_archive(cache, archive, verbose):
    """ calculate upgrades from a given archive
    :param cache: apt.Cache
    :param archive: str
    :param verbose: boolean
    """
    if archive:
        cache.set_filter(AptFilterUpgradeableSrc(archive))
    else:
        cache.set_filter(AptFilterUpgradeable())

    # { 'archive1' : { pkg1, pkg2 }, 'archive2' : { pkg3, pkg4 }}
    dictionary = dict()
    for pkg_name in cache.keys():
        archive = cache[pkg_name].candidate.origins[0].archive
        if archive not in dictionary:
            dictionary[archive] = set()

        dictionary[archive].add(pkg_name)

    upgradeable_count = 0
    for archive in dictionary:
        pkgset = dictionary[archive]
        amount = len(pkgset)
        upgradeable_count += amount

        list = "{}".format(', '.join(p for p in pkgset))
        report = "{} upgradeable packages from {}: {}".format(str(amount), archive, list)
        print_verbose(verbose, "{}".format(report))

    return upgradeable_count


def run_unattended_upgrades_report(verbose):
    """ run unattended_upgrades, parse the ouput and generate a report
    :param verbose: boolean
    """
    # Explicitly intended. If this becomes an interface problem later, we will deal with it
    cmd = "LANG=C unattended-upgrades --dry-run -v -d"
    grep1 = "| grep \"Packages that will be upgraded:\""
    awk = " | awk -F':' '{print $2}'"
    grep2 = " | grep -v ^[[:space:]]*$"
    proc = "{} {} {} {}".format(cmd, grep1, awk, grep2)
    pkgs = subprocess.check_output(proc, shell=True, stderr=subprocess.DEVNULL)

    unattended_count = 0
    for n in pkgs.split():
        unattended_count += 1

    list = "{}".format(', '.join(p.decode() for p in pkgs.split()))
    report = "{} upgradeable packages by unattended-upgrades: {}".format(unattended_count, list)
    print_verbose(verbose, "{}".format(report))
    return unattended_count


def run_report(cache, archive, verbose):
    """ calculate upgrades and report them
    :param cache: apt.Cache
    :param verbose: boolean
    :param archive: str
    """
    upgradeable_count = run_upgrade_report_archive(cache, archive, verbose)

    if archive:
        return
    else:
        unattended_count = run_unattended_upgrades_report(verbose)

    system = "{} upgradeable packages in the system".format(str(upgradeable_count))
    unattended = "{} upgradeable packages by unattended-upgrades".format(str(unattended_count))
    report ="{}, {}".format(system, unattended)
    print_verbose(verbose, "{}".format(report))


def main():
    parser = argparse.ArgumentParser(description="Utility to help with targeted upgrades of packages")
    parser.add_argument('-v', action='store_true', help="be verbose")
    parser.add_argument('-s', action='store_true',
                        help="simulate operations")
    parser.add_argument('source', nargs="?",
                        help="Main argument: source repository to upgrade from")
    parser.add_argument('--report', action='store_true',
                        help="Generate a report of pending upgrades per repository")
    args = parser.parse_args()

    if os.geteuid() != 0:
        sys.exit("root needed")

    cache = apt.cache.FilteredCache()
    print_verbose(args.v, "Updating cache ...")
    cache.update()
    cache.open(None)

    if args.report:
        run_report(cache, args.source, args.v)
    elif args.source:
        run_upgrade(cache, args.source, args.s, args.v)

    cache.close()

if __name__ == "__main__":
    main()
