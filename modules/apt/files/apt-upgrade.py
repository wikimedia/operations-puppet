#!/usr/bin/env python3

import argparse
import os
import sys
import apt
import apt_pkg
import subprocess
import socket

# Usage:
#
#  % apt-upgrade upgrade <suite> [-yv]
#  % apt-upgrade report [<suite>]
#  % apt-upgrade list
#
# make sure you hold+pin beforehand those packages that should not be upgraded


def print_verbose(verbose, msg):
    """ print information if verbose
    :param verbose: boolean
    :param msg: str
    """
    if verbose:
        print("{}: {}".format(socket.gethostname(), msg))


def print_verbose_pkg(verbose, pkg):
    """ print information about a package
    :param verbose: boolean
    :param pkg: Package
    """
    if not verbose:
        return
    archive = pkg.candidate.origins[0].archive
    name = pkg.name
    if pkg.is_installed:
        vorig = pkg.installed.version
    else:
        vorig = "absent"
    if not pkg.marked_delete:
        vdest = pkg.candidate.version
    else:
        vdest = "remove"
    print_verbose(verbose, '{}: {} {} --> {}'.format(archive, name, vorig, vdest))


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


def calculate_upgrades(cache, verbose):
    """ calculate upgrades and print the changes
    :param cache: apt.Cache
    :param verbose: boolean
    """
    for pkg_name in cache.keys():
        pkg_upgrade(verbose, cache[pkg_name])

    # report what we will be doing
    for pkg in cache.get_changes():
        print_verbose_pkg(verbose, pkg)

    return len(cache.get_changes())


def run_upgrade(cache, src, confirm, verbose):
    """ main upgrade routine: calculate upgrades and commit them
    :param cache: apt.Cache
    :param src: str
    :param confirm: boolean
    :param verbose: boolean
    """
    cache.set_filter(AptFilterUpgradeableSrc(src))

    if not calculate_upgrades(cache, verbose):
        print_verbose(verbose, 'no packages found to upgrade from {}'.format(src))
        return

    if not confirm:
        confirm = input("commit changes? [y/N]: ")
        if confirm[:1] != 'y' or confirm[:1] != 'Y':
            return

    cache.commit()


def run_upgrade_report_archive(cache, archive):
    """ calculate upgrades from a given archive
    :param cache: apt.Cache
    :param archive: str
    """
    if archive:
        cache.set_filter(AptFilterUpgradeableSrc(archive))
    else:
        cache.set_filter(AptFilterUpgradeable())

    return calculate_upgrades(cache, True)


def run_unattended_upgrades_report():
    """ run unattended_upgrades, parse the ouput and generate a report
    """
    # Explicitly intended. If this becomes an interface problem later, we will deal with it
    cmd = "LANG=C unattended-upgrades --dry-run -v -d"
    grep1 = "| grep \"Packages that will be upgraded:\""
    awk = " | awk -F':' '{print $2}'"
    grep2 = " | grep -v ^[[:space:]]*$"
    proc = "{} {} {} {}".format(cmd, grep1, awk, grep2)
    try:
        pkgs = subprocess.check_output(proc, shell=True, stderr=subprocess.DEVNULL)
    except Exception:
        pkgs = ""

    unattended_count = 0
    for n in pkgs.split():
        unattended_count += 1

    list = "{}".format(', '.join(p.decode() for p in pkgs.split()))
    report = "{} changes available for unattended-upgrades: {}".format(unattended_count, list)
    print_verbose(True, "{}".format(report))
    return unattended_count


def run_report(cache, archive):
    """ calculate upgrades and report them
    :param cache: apt.Cache
    :param archive: str
    """
    run_upgrade_report_archive(cache, archive)

    if archive:
        return

    run_unattended_upgrades_report()


def run_list(cache):
    """ asdasdasd
    :param cache: apt.Cache
    """
    cache.set_filter(AptFilterUpgradeable())
    calculate_upgrades(cache, False)
    archives = set()
    for pkg in cache.get_changes():
        archives.add(pkg.candidate.origins[0].archive)

    if len(archives) == 0:
        return

    print_verbose(True, "avaliable sources of upgrades: {}".format(", ".join(a for a in archives)))


def main():
    parser = argparse.ArgumentParser(description="Utility to help with upgrades of packages")
    subparser = parser.add_subparsers(help="possible operations", dest="operation")
    subparser.add_parser("list", help="list available sources of upgrades")
    upgrade_parser = subparser.add_parser("upgrade",
                                          help="upgrade packages from a given archive")
    upgrade_parser.add_argument("archive", action="store",
                                help="archive to upgrade packages from")
    upgrade_parser.add_argument("-y", action="store_true",
                                help="actually perform changes (will prompt otherwise)")
    upgrade_parser.add_argument('-v', action='store_true', help="be verbose in operations")

    report_parser = subparser.add_parser("report",
                                         help="report pending package upgrades")
    report_parser.add_argument("archive", action="store", nargs="?",
                               help="archive to report pending upgrades from")

    args = parser.parse_args()

    if os.geteuid() != 0:
        sys.exit("root needed")

    cache = apt.cache.FilteredCache()
    print_verbose(True, "updating apt cache ...")
    cache.update()
    cache.open(None)

    if args.operation == "upgrade":
        run_upgrade(cache, args.archive, args.y, args.v)
    elif args.operation == "report":
        run_report(cache, args.archive)
    elif args.operation == "list":
        run_list(cache)

    cache.close()


if __name__ == "__main__":
    main()
