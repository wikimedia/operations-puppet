#!/usr/bin/env python3

import argparse
import os
import sys
import apt
import apt_pkg
import socket
import logging
import re

# Usage:
#
#  % apt-upgrade [-un] [-f exclude_file] [-x regex] upgrade <suite> [-yh]
#  % apt-upgrade [-un] [-f exclude_file] [-x regex] report [<suite>] [-h]
#  % apt-upgrade [-un] [-f exclude_file] [-x regex] list [-h]
#
# make sure you hold+pin beforehand those packages that should not be upgraded
#
# More info at: https://wikitech.wikimedia.org/wiki/Apt-upgrades


def print_output_pkg(tag, pkg):
    """ print information about a package
    :param tag: str
    :param pkg: Package
    """
    archive = pkg.candidate.origins[0].archive
    if not archive:
        archive = "[unknown]"
    name = pkg.name
    if pkg.is_installed:
        vorig = pkg.installed.version
    else:
        vorig = "[absent]"
    if not pkg.marked_delete:
        vdest = pkg.candidate.version
    else:
        vdest = "[remove]"
    logging.info('{}: {} {} --> {} {}'.format(archive, name, vorig, vdest, tag))


def pkg_upgrade(pkg):
    """ try to mark a package for upgrade
    :param pkg: Package
    """
    if not pkg.is_installed:
        return False
    try:
        pkg.mark_upgrade()
        marked_upgrade = True
    except apt_pkg.Error as e:
        logging.info('{} not for upgrade: {}'.format(pkg.name, str(e)))
        pkg.mark_keep()
        marked_upgrade = False

    return marked_upgrade


class AptFilterUpgradeableSrc(apt.cache.Filter):
    """ filter for python-apt cache to filter only packages upgradeable from a
    specific source.
    """

    def __init__(self, src):
        super().__init__()
        self.src = src

    def apply(self, pkg):
        """ filtering function: installed and upgradeable pkgs, from a given archive
        :param pkg: Package
        """
        if pkg.is_installed and pkg.is_upgradable and pkg.candidate.origins[0].archive == self.src:
            return True

        return False


class AptFilterUpgradeable(apt.cache.Filter):
    """ filter for python-apt cache to get only upgradeable packages.
    """

    def apply(self, pkg):
        """ filtering function: installed and upgradeable pkgs
        :param pkg: Package
        """

        if pkg.is_installed and pkg.is_upgradable:
            return True

        return False


def sort_pkgs_by_archive(pkg_list):
    """ sort packages by the archive attribute of the origin of the candidate version
    :param pkg_list: Package list
    """
    return sorted(pkg_list, key=lambda pkg: pkg.candidate.origins[0].archive)


def exclude_packages(pkg_list, exclude_regex_set):
    """ exclude packages (mark as keep) if the match a regex in the set
    :param cache: apt.Cache
    :param file: str
    :param exclude_regex_file: set(regex)
    """
    for regex in exclude_regex_set:
        for pkg in pkg_list:
            if regex.match(pkg.name):
                print_output_pkg("[excluded]", pkg)
                pkg.mark_keep()


def calculate_upgrades(cache, exclude_regex_set):
    """ calculate upgrades and print the changes
    :param cache: apt.Cache
    :param exclude_regex_set: set(regex)
    """
    for pkg_name in cache.keys():
        pkg_upgrade(cache[pkg_name])

    pkg_list = sort_pkgs_by_archive(cache.get_changes())
    exclude_packages(pkg_list, exclude_regex_set)

    # excluding packages generates new changes, so sort again
    pkg_list = sort_pkgs_by_archive(cache.get_changes())
    for pkg in pkg_list:
        print_output_pkg("", pkg)

    return len(pkg_list)


def run_upgrade(cache, src, confirm, exclude_regex_set):
    """ main upgrade routine: calculate upgrades and commit them
    :param cache: apt.Cache
    :param src: str
    :param confirm: boolean
    :param exclude_regex_set: set(regex)
    """
    cache.set_filter(AptFilterUpgradeableSrc(src))

    if not calculate_upgrades(cache, exclude_regex_set):
        logging.info('no packages found to upgrade from {}'.format(src))
        return

    if not confirm:
        confirm = input("commit changes? [y/N]: ")
        if confirm[:1] != "y" and confirm[:1] != "Y":
            return

    cache.commit()


def run_report(cache, archive, exclude_regex_set):
    """ calculate upgrades and report them
    :param cache: apt.Cache
    :param archive: str
    :param exclude_regex_set: set(regex)
    """
    if archive:
        cache.set_filter(AptFilterUpgradeableSrc(archive))
    else:
        cache.set_filter(AptFilterUpgradeable())

    return calculate_upgrades(cache, exclude_regex_set)


def run_list(cache, exclude_regex_set):
    """ list available archives from which packages can be upgraded
    :param cache: apt.Cache
    :param exclude_regex_set: set(regex)
    """
    cache.set_filter(AptFilterUpgradeable())
    logging.disable(logging.INFO)
    calculate_upgrades(cache, exclude_regex_set)
    logging.disable(logging.NOTSET)
    archives = set()
    for pkg in cache.get_changes():
        archive = pkg.candidate.origins[0].archive
        if archive:
            archives.add(archive)
        else:
            archives.add("[unknown]")

    if len(archives) == 0:
        return

    logging.info("{}".format(", ".join(a for a in sorted(archives))))


def exclude_regex_set(exclude_file, exclude_list):
    """ calculates a list of regex to exclude files
    :param exclude_file: str (file)
    :param exclude_list: list(str)
    """

    regex_set = set()

    if exclude_list:
        for element in exclude_list:
            regex = re.compile(element)
            regex_set.add(regex)

    if exclude_file:
        try:
            f = open(exclude_file)
        except OSError as e:
            logging.warning("can't open exclude file: {}". format(e))
            return regex_set

        for line in f.readlines():
            regex = re.compile(line[:-1])  # clean '\n'
            regex_set.add(regex)

        f.close()

    return regex_set


def main():
    parser = argparse.ArgumentParser(description="Utility to help with upgrades of packages")
    parser.add_argument("-u", action="store_true", help="don't run cache update")
    parser.add_argument("-n", action="store_true", help="don't print the node name")
    parser.add_argument("-f", "--exclude-file",
                        help="read file (a regex per line) with packages to be excluded")
    parser.add_argument("-x", "--exclude", action="append",
                        help="a regex of packages to be excluded")
    subparser = parser.add_subparsers(help="possible operations (pass -h to know usage of each)",
                                      dest="operation")
    subparser.add_parser("list", help="list available sources of upgrades")
    upgrade_parser = subparser.add_parser("upgrade",
                                          help="upgrade packages from a given archive")
    upgrade_parser.add_argument("archive", action="store",
                                help="archive to upgrade packages from")
    upgrade_parser.add_argument("-y", action="store_true",
                                help="actually perform changes (will prompt otherwise)")
    report_parser = subparser.add_parser("report",
                                         help="report pending package upgrades")
    report_parser.add_argument("archive", action="store", nargs="?",
                               help="archive to report pending upgrades from")

    args = parser.parse_args()

    if os.geteuid() != 0:
        sys.exit("root needed")

    if not args.operation:
        parser.print_help()
        sys.exit(1)

    if args.n:
        logging_format = "%(message)s"
    else:
        logging_format = "{}: %(message)s".format(socket.gethostname())

    logging.basicConfig(format=logging_format, level=logging.INFO, stream=sys.stdout)
    os.environ['DEBIAN_FRONTEND'] = "noninteractive"
    cache = apt.cache.FilteredCache()
    regex_set = exclude_regex_set(args.exclude_file, args.exclude)

    if not args.u:
        logging.info("updating apt cache ...")
        cache.update()

    cache.open(None)

    if args.operation == "upgrade":
        run_upgrade(cache, args.archive, args.y, regex_set)
    elif args.operation == "report":
        run_report(cache, args.archive, regex_set)
    elif args.operation == "list":
        run_list(cache, regex_set)

    cache.close()
    logging.shutdown()


if __name__ == "__main__":
    main()
