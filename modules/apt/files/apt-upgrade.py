#!/usr/bin/env python3

import argparse
import os
import sys
import apt
import apt_pkg
import socket

# Usage:
#
#  % apt-upgrade [-un] upgrade <suite> [-yvh]
#  % apt-upgrade [-un] report [<suite>] [-h]
#  % apt-upgrade [-un] list [-h]
#
# make sure you hold+pin beforehand those packages that should not be upgraded

print_enabled = False
print_hostname = False


def print_output(msg):
    """ printing function. Reads above global variables
    :param msg: str
    """
    if not print_enabled:
        return

    if print_hostname:
        hostname = "{}: ".format(socket.gethostname())
    else:
        hostname = ""

    print("{}{}".format(hostname, msg))


def print_output_pkg(pkg):
    """ print information about a package
    :param pkg: Package
    """
    if not print_enabled:
        return
    archive = pkg.candidate.origins[0].archive
    if not archive:
        archive = "[unknown]"
    name = pkg.name
    if pkg.is_installed:
        vorig = pkg.installed.version
    else:
        vorig = "absent"
    if not pkg.marked_delete:
        vdest = pkg.candidate.version
    else:
        vdest = "remove"
    print_output('{}: {} {} --> {}'.format(archive, name, vorig, vdest))


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
        print_output('{} not for upgrade: {}'.format(pkg.name, str(e)))
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


def calculate_upgrades(cache):
    """ calculate upgrades and print the changes
    :param cache: apt.Cache
    """
    for pkg_name in cache.keys():
        pkg_upgrade(cache[pkg_name])

    # report changes
    for pkg in sort_pkgs_by_archive(cache.get_changes()):
        print_output_pkg(pkg)

    return len(cache.get_changes())


def run_upgrade(cache, src, confirm):
    """ main upgrade routine: calculate upgrades and commit them
    :param cache: apt.Cache
    :param src: str
    :param confirm: boolean
    """
    cache.set_filter(AptFilterUpgradeableSrc(src))

    if not calculate_upgrades(cache):
        print_output('no packages found to upgrade from {}'.format(src))
        return

    if not confirm:
        confirm = input("commit changes? [y/N]: ")
        if confirm[:1] != "y" and confirm[:1] != "Y":
            return

    cache.commit()


def run_report(cache, archive):
    """ calculate upgrades and report them
    :param cache: apt.Cache
    :param archive: str
    """
    global print_enabled
    if archive:
        cache.set_filter(AptFilterUpgradeableSrc(archive))
    else:
        cache.set_filter(AptFilterUpgradeable())

    print_enabled = True
    return calculate_upgrades(cache)


def run_list(cache):
    """ list available archives from which packages can be upgraded
    :param cache: apt.Cache
    """
    global print_enabled
    cache.set_filter(AptFilterUpgradeable())
    print_enabled = False
    calculate_upgrades(cache)
    archives = set()
    for pkg in cache.get_changes():
        archive = pkg.candidate.origins[0].archive
        if archive:
            archives.add(archive)
        else:
            archives.add("[unknown]")

    if len(archives) == 0:
        return

    print_enabled = True
    print_output("{}".format(", ".join(a for a in sorted(archives))))


def main():
    global print_enabled
    global print_hostname
    parser = argparse.ArgumentParser(description="Utility to help with upgrades of packages")
    parser.add_argument("-u", action="store_true", help="don't run cache update")
    parser.add_argument("-n", action="store_true", help="don't print the node name")
    subparser = parser.add_subparsers(help="possible operations (pass -h to know usage of each)",
                                      dest="operation")
    subparser.add_parser("list", help="list available sources of upgrades")
    upgrade_parser = subparser.add_parser("upgrade",
                                          help="upgrade packages from a given archive")
    upgrade_parser.add_argument("archive", action="store",
                                help="archive to upgrade packages from")
    upgrade_parser.add_argument("-y", action="store_true",
                                help="actually perform changes (will prompt otherwise)")
    upgrade_parser.add_argument('-v', action='store_true', help="report changes to be performed")

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

    print_hostname = not args.n
    cache = apt.cache.FilteredCache()

    if not args.u:
        print_enabled = True
        print_output("updating apt cache ...")
        cache.update()

    cache.open(None)

    if args.operation == "upgrade":
        print_enabled = args.v
        run_upgrade(cache, args.archive, args.y)
    elif args.operation == "report":
        run_report(cache, args.archive)
    elif args.operation == "list":
        run_list(cache)

    cache.close()


if __name__ == "__main__":
    main()
