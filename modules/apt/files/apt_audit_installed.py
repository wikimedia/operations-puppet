#!/usr/bin/env python3
"""Manage installed packages vs Puppet managed packages"""

from argparse import ArgumentParser
from apt.cache import Cache


def get_args():
    """Parse arguments"""
    parser = ArgumentParser(description=__doc__)
    parser.add_argument('--base-packages', default='/usr/local/share/apt/base_packages.txt')
    return parser.parse_args()


def get_puppet_managed_pkgs():
    """parse the resources file to produce a list of packages installed via puppet"""
    pkgs = set()
    with open('/var/lib/puppet/state/resources.txt') as resources_fh:
        for line in resources_fh.readlines():
            if line.startswith('package['):
                pkgs.add(line.strip().split('[')[1][:-1])
    return pkgs


def get_base_pkgs(base_packages: str):
    """Return a list of base packages"""
    pkgs = set()
    with open(base_packages) as base_pkgs_fh:
        for line in base_pkgs_fh.readlines():
            if line.startswith('#'):
                continue
            pkgs.add(line.strip())
    return pkgs


def main():
    """main entry point"""
    args = get_args()
    installed_pkgs = set(pkg.name for pkg in Cache()
                         if pkg.is_installed and not pkg.is_auto_installed)
    additional_pkgs = installed_pkgs - get_puppet_managed_pkgs() - get_base_pkgs(args.base_packages)
    for pkg in additional_pkgs:
        print(pkg)


if __name__ == '__main__':
    raise SystemExit(main())
