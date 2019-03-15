#!/usr/bin/env python3
#
# Icinga check for down OSPF (v2/v3) sessions.
# Returns CRITICAL if the number of UP sessions is lower than the number of UP P2P interfaces.
# Or if the number of OSPFv2 is different from OSPFv3
#
# Usage:
# python3 check_ospf.py --host HOSTNAME --community COMMUNITY
#
# - Ignores the DOWN interfaces as we already have an Icinga check for that
#
# Arzhel Younsi
# ayounsi@wikimedia.org

import argparse
import sys

from collections import Counter

from snimpy.manager import load, Manager

# https://tools.ietf.org/html/rfc1253
STATE_P2P = 4  # Interface in P2P state
NBR_STATE_FULL = 8  # OSPF session with neighbor in "full" state
ICINGA_OK = 0
ICINGA_CRITICAL = 2
ICINGA_UNKNOWN = 3


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--host", dest='host', required=True, help="Target hostname")
    parser.add_argument("--community", dest='community', required=True, help="SNMP community")
    options = parser.parse_args()

    load('OSPF-MIB')
    load('OSPFV3-MIB')
    snimpyManager = Manager(options.host, options.community, 2, cache=True)

    return_code = ICINGA_OK
    output_messages = []
    counters = Counter()

    # OSPFv2
    for index, ifState in snimpyManager.ospfIfState.items():
        if ifState == STATE_P2P:  # Count configured P2P interfaces
            # Workaround a bug where interface 0.0.0.0 shows up as P2P
            if snimpyManager.ospfIfIpAddress[index] != '0.0.0.0':
                counters['p2pif'] += 1

    for index, nbrState in snimpyManager.ospfNbrState.items():
        if nbrState == NBR_STATE_FULL:  # Count UP neighbors
            counters['up'] += 1

    # If less neighbors than P2P interfaces, alert
    if counters['up'] < counters['p2pif']:
        return_code = ICINGA_CRITICAL

    output_messages.append("OSPFv2: {up}/{tot} UP".format(up=counters['up'],
                                                          tot=counters['p2pif']))

    # OSPFv3, same as OSPFv2
    for index, ifState in snimpyManager.ospfv3IfState.items():
        if ifState == STATE_P2P:
            counters['v3_p2pif'] += 1

    for index, nbrState in snimpyManager.ospfv3NbrState.items():
        if nbrState == NBR_STATE_FULL:
            counters['v3_up'] += 1

    if counters['v3_up'] < counters['v3_p2pif']:
        return_code = ICINGA_CRITICAL

    output_messages.append("OSPFv3: {up}/{tot} UP".format(up=counters['v3_up'],
                                                          tot=counters['v3_p2pif']))

    # Ensure we have as many OSPFv2 as OSPFv3 neighbors
    if counters['v3_p2pif'] != counters['p2pif']:
        return_code = ICINGA_CRITICAL
        output_messages.append("{} v2 P2P interfaces vs. {} v3 P2P interfaces".format(
            counters['p2pif'], counters['v3_p2pif']))

    print(' ; '.join(output_messages))

    return(return_code)


if __name__ == '__main__':
    try:
        sys.exit(main())
    except Exception as err:
        print("Error running check: {}".format(err))
        sys.exit(ICINGA_UNKNOWN)
