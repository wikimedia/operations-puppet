#!/usr/bin/env python3

# Icinga check for down BFD sessions.
# Requires the MIBs: mib-jnx-bfd-exp, mib-jnx-exp, mib-jnx-smi
# Returns CRITICAL if at least one BFD session is down, OK otherwise.
#
# Usage:
# python3 check_bfd --host HOSTNAME --community COMMUNITY
#
# ayounsi@wikimedia.org

import argparse
import ipaddress
import sys

from snimpy.manager import Manager
from snimpy.manager import load


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--host", nargs=1, dest='host', required=True, help="Target hostname")
    parser.add_argument("--community", nargs=1,
                        dest='community', required=True, help="SNMP community")
    options = parser.parse_args()
    load("BFD-STD-MIB")

    snimpyManager = Manager(options.host[0], options.community[0], 2, cache=True)

    return_code = 0
    return_message = []
    up_count = 0
    down_count = 0
    adminDown_count = 0

    for index in snimpyManager.bfdSessState:
        if snimpyManager.bfdSessAddrType[index] == 1:  # v4 session
            peerIP = ipaddress.IPv4Address(snimpyManager.bfdSessAddr[index])
        elif snimpyManager.bfdSessAddrType[index] == 2:  # v6 session
            peerIP = ipaddress.IPv6Address(snimpyManager.bfdSessAddr[index])
        state = snimpyManager.bfdSessState[index]
        # States: adminDown(1), down(2), init(3), up(4)
        if state == 2 or state == 3:
            down_count += 1
            return_code = 2
            return_message.append("BFD neighbor {} down".format(peerIP))
        elif state == 4:
            up_count += 1
        elif state == 1:
            adminDown_count += 1

    if return_code == 0:
        print('OK:' + ' UP: ' + str(up_count) + ' AdminDown: '
              + str(adminDown_count) + ' Down: ' + str(down_count))
        print("OK: UP: {} AdminDown: {} Down: {}".format(up_count, adminDown_count, down_count))
    else:
        print("CRIT: Down: {}".format(down_count))
        print('\n'.join(return_message))

    sys.exit(return_code)


if __name__ == "__main__":
    main()
