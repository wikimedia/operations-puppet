#!/usr/bin/python

import argparse
import os.path
import re
import subprocess
import sys
import glob


def main():

    options = parse_args()
    if options.driver:
        driver = options.driver
    else:
        driver = autoDetectDriver()

    try:
        if driver is None:
            print 'OK: no RAID installed'
            status = 0
        elif driver == 'megacli':
            status = checkMegaSas(options.policy)
        elif driver == 'mpt':
            status = checkmptsas()
        elif driver == 'md':
            status = checkSoftwareRaid()
        else:
            print('WARNING: %s is not yet supported '
                  'by this check script' % (driver))
            status = 1
    except:
        error = sys.exc_info()[1]
        print 'WARNING: encountered exception: ' + str(error)
        status = 1

    if status == 0:
        print 'OK'
    sys.exit(status)


def parse_args():
    """Parse command line arguments"""

    parser = argparse.ArgumentParser(
        description=('Checks the state of the raid, trying to autodetect'
                     'the right RAID controller (hw. & sw.) if not provided'))
    parser.add_argument(
        'driver', nargs='?', default=None,
        help='Optional argument indicating the driver to use.')
    parser.add_argument(
        '-p', '--policy', default=None,
        help=('Check that the given cache write policy is currently applied '
              '(for example WriteBack or WriteThrough)'))

    return parser.parse_args()


def autoDetectDriver():
    if len(glob.glob("/sys/bus/pci/drivers/megaraid_sas/00*")) > 0:
        return 'megacli'

    try:
        open("/proc/scsi/mptsas/0", "r")
        return "mpt"
    except IOError:
        pass

    # Try mdadm
    devices = getSoftwareRaidDevices()
    if len(devices):
        return 'md'

    return None


def getSoftwareRaidDevices():
    if not os.path.exists('/sbin/mdadm'):
        return []

    try:
        proc = subprocess.Popen(['/sbin/mdadm', '--detail', '--scan'],
                                stdout=subprocess.PIPE)
    except:
        return []

    regex = re.compile('^ARRAY\s+([^ ]*) ')
    devices = []
    for line in proc.stdout:
        m = regex.match(line)
        if m is not None:
            devices.append(m.group(1))
    proc.wait()

    return devices


def checkmptsas():
    status = 0
    if not os.path.exists('/usr/sbin/mpt-status'):
        print 'mpt-status not installed'
        return 255

    try:
        proc = subprocess.Popen([
                                '/usr/sbin/mpt-status',
                                '--autoload',
                                '--status_only'],
                                stdout=subprocess.PIPE)
    except Exception as e:
        print 'Unable to execute mpt-status: %s' % e
        return 254

    log_drive_re = re.compile('^log_id \d (\w+)$')
    phy_drive_re = re.compile('^phys_id (\d) (\w+)$')

    for line in proc.stdout:
        m = log_drive_re.match(line)
        if m is not None:
            print 'RAID STATUS: %s' % m.group(1)
            if m.group(1) != 'OPTIMAL':
                status = 1
        m = phy_drive_re.match(line)
        if m is not None:
            print 'DISK %s STATUS: %s' % (m.group(1), m.group(2))

    proc.wait()

    return status


def checkMegaSas(policy=None):
    try:
        proc = subprocess.Popen(['/usr/sbin/megacli',
                                '-LDInfo', '-LALL', '-aALL', '-NoLog'],
                                stdout=subprocess.PIPE)
    except:
        error = sys.exc_info()[1]
        print 'WARNING: error executing megacli: %s' % str(error)
        return 1

    stateRegex = re.compile('^State\s*:\s*([^\n]*)')
    drivesRegex = re.compile('^Number Of Drives( per span)?\s*:\s*([^\n]*)')
    configuredRegex = re.compile('^Adapter \d+: No Virtual Drive Configured')
    writePolicyRegex = re.compile('^Current Cache Policy\s*:\s*([^,]*)')

    numPD = numLD = failedLD = wrongPolicyLD = 0
    states = []
    currentWrongPolicies = []
    lines = 0
    match = False

    for line in proc.stdout:
        if len(line.strip()) and not line.startswith('Exit Code'):
            lines += 1

        m = stateRegex.match(line)
        if m is not None:
            match = True
            numLD += 1
            state = m.group(1)
            if state != 'Optimal':
                failedLD += 1
                states.append(state)
            continue

        m = drivesRegex.match(line)
        if m is not None:
            match = True
            numPD += int(m.group(2))
            continue

        m = configuredRegex.match(line)
        if m is not None:
            match = True
            continue

        if policy is not None:
            m = writePolicyRegex.match(line)
            if m is not None:
                match = True
                currentPolicy = m.group(1)
                if currentPolicy != policy:
                    wrongPolicyLD += 1
                    currentWrongPolicies.append(currentPolicy)
            continue

    ret = proc.wait()
    if ret != 0:
        print 'WARNING: megacli returned exit status %d' % (ret)
        return 1

    if lines == 0:
        print 'WARNING: no known controller found'
        return 1

    if not match:
        print 'WARNING: parse error processing megacli output'
        return 1

    if numLD == 0:
        print 'OK: no disks configured for RAID'
        return 0

    if failedLD > 0:
        print 'CRITICAL: %d failed LD(s) (%s)' % (failedLD, ", ".join(states))
        return 2

    if wrongPolicyLD > 0:
        print(('CRITICAL: %d LD(s) must have write cache policy %s, '
               'currently using: %s') % (wrongPolicyLD, policy,
                                         ", ".join(currentWrongPolicies)))
        return 2

    if policy is None:
        print 'OK: optimal, %d logical, %d physical' % (numLD, numPD)
    else:
        print 'OK: optimal, %d logical, %d physical, %s policy' % (
            numLD, numPD, policy)
    return 0


def checkSoftwareRaid():
    devices = getSoftwareRaidDevices()
    if len(devices) == 0:
        print 'WARNING: unexpectedly checked no devices'
        return 1

    args = ['/sbin/mdadm', '--detail']
    args.extend(devices)
    try:
        proc = subprocess.Popen(args, stdout=subprocess.PIPE)
    except:
        error = sys.exc_info()[1]
        print 'WARNING: error executing mdadm: %s' % str(error)
        return 1

    dre = '^(/[^ ]*):$'
    deviceRegex = re.compile(dre)
    sre = '^ *(Active|Working|Failed|Spare) Devices *: *(\d+)'
    statRegex = re.compile(sre)
    statere = '^ *State *: *(.+) *'
    stateRegex = re.compile(statere)
    currentDevice = None
    degraded = False
    stats = {
        'Active': 0,
        'Working': 0,
        'Failed': 0,
        'Spare': 0
    }
    for line in proc.stdout:
        m = stateRegex.match(line)
        if m is not None:
            if 'degraded' in m.group(1):
                degraded = True
            continue

        m = deviceRegex.match(line)
        if m is None:
            if currentDevice is None:
                continue
        else:
            currentDevice = m.group(1)
            continue

        m = statRegex.match(line)
        if m is None:
            continue

        stats[m.group(1)] += int(m.group(2))

    ret = proc.wait()
    if ret != 0:
        print 'WARNING: mdadm returned exit status %d' % (ret)
        return 1

    msg = ''
    if degraded:
        msg += 'State: degraded'
    for name in ('Active', 'Working', 'Failed', 'Spare'):
        if msg != '':
            msg += ', '
        msg += name + ': ' + str(stats[name])

    if degraded or stats['Failed'] > 0:
        print 'CRITICAL: ' + msg
        return 2
    else:
        print 'OK: ' + msg
        return 0


main()
