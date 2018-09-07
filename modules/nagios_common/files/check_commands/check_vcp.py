#!/usr/bin/env python3

# Icinga check for down VC ports.
# Requires the MIBs: mib-jnx-virtualchassis, mib-jnx-ex-smi, mib-jnx-chassis, mib-jnx-smi
# Returns CRITICAL if at least one VC port is down or unknown, OK otherwise.
#
# Usage:
# python3 check_vcp.py --host HOSTNAME --community COMMUNITY
#
# Some limitations on the data exposed via SNMP:
#
# - Doesn't alert if the status is "Absent" (cable unplugged on both sides)
# - Doesn't return the FPC nor port # (present in the MIB but not in the SNMP reply)
# - [Untested] Probably doesn't alert if the link is UP
#   but the adjacency not established (Junos bug?)
#
# ayounsi@wikimedia.org

from snimpy.manager import Manager
from snimpy.manager import load
from snimpy.snmp import SNMPNoSuchObject
import sys
import argparse

parser = argparse.ArgumentParser()
parser.add_argument("--host", nargs=1, dest='host', required=True, help="Target hostname")
parser.add_argument("--community", nargs=1, dest='community', required=True, help="SNMP community")
options = parser.parse_args()

load('JUNIPER-VIRTUALCHASSIS-MIB')

snimpyManager = Manager(options.host[0], options.community[0], 2, cache=True)

return_code = 0
return_message = []
up_count = 0
down_count = 0
unknown_count = 0

for index in snimpyManager.jnxVirtualChassisPortAdminStatus:
    adminStatus = snimpyManager.jnxVirtualChassisPortAdminStatus[index]
    operStatus = snimpyManager.jnxVirtualChassisPortOperStatus[index]
    try:
        portName = snimpyManager.jnxVirtualChassisPortName[index]
        fpcId = snimpyManager.jnxVirtualChassisFpcId[index]
    except SNMPNoSuchObject:
        portName = 'N/A'
        fpcId = 'N/A'

    if adminStatus == 3:  # If adminStatus is Unknown
        unknown_count += 1
        return_code = 2  # Still alert as critical
        return_message.append("FPC {} port {} unknown status".format(fpcId, portName))
    elif adminStatus == 1:  # If adminStatus is UP
        if operStatus == 1:
            up_count += 1
        elif operStatus == 2:
            down_count += 1
            return_code = 2
            return_message.append("FPC {} port {} down".format(fpcId, portName))
        elif operStatus == 3:
            unknown_count += 1
            return_code = 2
            return_message.append("FPC {} port {} unknown".format(fpcId, portName))

if return_code == 0:
    print("OK: UP: {}".format(up_count))
else:
    print("CRIT: Down: {} Unknown: {}".format(down_count, unknown_count))
    print('\n'.join(return_message))

sys.exit(return_code)
