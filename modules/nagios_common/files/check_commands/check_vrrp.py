#!/usr/bin/env python3

# Copyright 2017 Faidon Liambotis
# Copyright 2017 Wikimedia Foundation, Inc.
#
# This nagios plugin is free software, and comes with ABSOLUTELY NO WARRANTY.
# It may be used, redistributed and/or modified under the terms of the GNU
# General Public Licence (see http://www.fsf.org/licensing/licenses/gpl.txt).
#
# Example usage:
#   check_vrrp -L cr1-eqiad.wikimedia.org -R cr2-eqiad.wikimedia.org -c s3cr3t

"""Nagios/Icinga plugin to check the configuration and consistency of VRRP
interface states between two routers."""

import argparse
import logging
import nagiosplugin
from snimpy import manager as snmp

logger = logging.getLogger("nagiosplugin")  # pylint: disable=invalid-name


class VRRP(nagiosplugin.Resource):
    """The nagiosplugin Resource that fetches interface state and probes."""

    def __init__(self, left_m, right_m):
        self.left = self.fetch_interface_state(left_m)
        self.right = self.fetch_interface_state(right_m)

    @staticmethod
    def fetch_interface_state(snmp_mgr):
        """Fetch interface state from SNMP."""

        # pylint: disable=invalid-name
        interfaces = {}
        for ifIndex, vrrpOperVrId in snmp_mgr.vrrpOperState:
            state = snmp_mgr.vrrpOperState[(ifIndex, vrrpOperVrId)]
            name = str(snmp_mgr.ifName[ifIndex])
            interfaces[name] = state

        return interfaces

    def probe(self):
        misconfigured = sorted(set(self.left) ^ set(self.right))
        yield nagiosplugin.Metric("misconfigured", len(misconfigured))
        if misconfigured:
            logger.warning("Misconfigured: %s", ", ".join(misconfigured))

        inconsistent = []
        for interface in set(self.left) & set(self.right):
            if self.left[interface] == self.right[interface]:
                status = self.left[interface]
                inconsistent.append("{} (both {})".format(interface, status))
        inconsistent.sort()

        yield nagiosplugin.Metric("inconsistent", len(inconsistent))
        if inconsistent:
            logger.warning("Inconsistent state: %s", ", ".join(inconsistent))


class BooleanContext(nagiosplugin.Context):
    """Returns Critical if metric is > 0, OK otherwise"""

    def evaluate(self, metric, resource):
        if metric.value > 0:
            state = nagiosplugin.Critical
        else:
            state = nagiosplugin.Ok

        return self.result_cls(state, None, metric)


class AllSummary(nagiosplugin.Summary):
    """Return all results, not just the most significant one"""

    def ok(self, results):
        return self.problem(results)

    def problem(self, results):
        return ", ".join([str(r) for r in results])


@nagiosplugin.guarded
def main():
    """Main function."""

    argp = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.ArgumentDefaultsHelpFormatter
    )
    argp.add_argument(
        "-L",
        "--left-host",
        required=True,
        help="Left-hand side of the router to check against",
    )
    argp.add_argument(
        "-R",
        "--right-host",
        required=True,
        help="Right-hand side of the router to check against",
    )
    argp.add_argument(
        "-c", "--community", default="public", help="SNMP community to use"
    )
    argp.add_argument("-v", "--version", type=int, default=2, help="SNMP version")
    argp.add_argument(
        "-V",
        "--verbose",
        action="count",
        default=0,
        help="increase output verbosity (use up to 3 times)",
    )
    args = argp.parse_args()

    snmp.load("IF-MIB")
    snmp.load("VRRP-MIB")
    snmp_mgr1 = snmp.Manager(
        host=args.left_host, community=args.community, version=args.version, cache=True
    )
    snmp_mgr2 = snmp.Manager(
        host=args.right_host, community=args.community, version=args.version, cache=True
    )

    fmt = "{value} {name} interfaces"
    check = nagiosplugin.Check(
        VRRP(snmp_mgr1, snmp_mgr2),
        BooleanContext("misconfigured", fmt_metric=fmt),
        BooleanContext("inconsistent", fmt_metric=fmt),
        AllSummary(),
    )
    check.main(verbose=args.verbose)


if __name__ == "__main__":
    main()
