#!/usr/bin/python
#####################################################################
### THIS FILE IS MANAGED BY PUPPET
### puppet:///modules/base/monitoring/check-raid.py
#####################################################################

import os
import os.path
import re
import subprocess
import sys
import glob


def main():
    osName = os.uname()[0]
    if osName == 'SunOS':
        utilities = ['zpool']
    elif osName == 'Linux':
        utilities = getLinuxUtilities()
    else:
        print ('WARNING: operating system "%s" is not '
               'supported by this check script' % (osName))
        sys.exit(1)

    try:
        if len(utilities) == 0:
            print 'OK: no RAID installed'
            status = 0
        else:
            status = 0
            for u in utilities:
                # these should all return 0 for success,
                # 1 for warning (including 'can't run the check'),
                # 2 for raid failure
                if u == 'arcconf':
                    status = status | checkAdaptec()
                elif u == 'tw_cli':
                    status = status | check3ware()
                elif u == 'MegaCli':
                    status = status | checkMegaSas()
                elif u == 'zpool':
                    status = status | checkZfs()
                elif u == 'mptsas':
                    status = status | checkmptsas()
                elif u == 'mdadm':
                    status = status | checkSoftwareRaid()
                else:
                    print ('WARNING: %s is not yet supported '
                           'by this check script' % (u))
                    status = status | 1
    except:
        error = sys.exc_info()[1]
        print 'WARNING: check-raid.py encountered exception: ' + str(error)
        status = status | 1

    if status > 2:
        status = 2
    sys.exit(status)


def getLinuxUtilities():
    utils = []
    f = open("/proc/devices", "r")
    regex = re.compile('^\s*\d+\s+(\w+)')
    for line in f:
        m = regex.match(line)
        if m is None:
            continue
        name = m.group(1)

        if name == 'aac':
            utils.append('arcconf')
            continue
        elif name == 'twe':
            utils.append('tw_cli')
            continue
        elif name == 'megadev':
            utils.append('megarc')
            continue

    f.close()

    if len(glob.glob("/sys/bus/pci/drivers/megaraid_sas/00*")) > 0:
        utils.append('MegaCli')

    try:
        f = open("/proc/scsi/mptsas/0", "r")
        utils.append("mptsas")
    except IOError:
        pass

    # Try mdadm
    devices = getSoftwareRaidDevices()
    if len(devices):
        utils.append('mdadm')

    return utils


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
        print 'WARNING: mpt-status not installed'
        return 1

    try:
        proc = subprocess.Popen([
                                '/usr/sbin/mpt-status',
                                '--autoload',
                                '--status_only'],
                                stdout=subprocess.PIPE)
    except Exception as e:
        print 'WARNING: Unable to execute mpt-status: %s' % e
        return 1

    log_drive_re = re.compile('^log_id \d (\w+)$')
    phy_drive_re = re.compile('^phys_id (\d) (\w+)$')

    for line in proc.stdout:
        m = log_drive_re.match(line)
        if m is not None:
            print 'RAID STATUS: %s' % m.group(1)
            if m.group(1) != 'OPTIMAL':
                status = 2
        m = phy_drive_re.match(line)
        if m is not None:
            print 'DISK %s STATUS: %s' % (m.group(1), m.group(2))

    proc.wait()

    return status


def checkAdaptec():
    # Need to change directory so that the log file goes to the right place
    oldDir = os.getcwd()
    os.chdir('/var/log')
    devNull = open('/dev/null', 'w')

    # Run the command
    try:
        proc = subprocess.Popen(['/usr/sbin/arcconf', 'getconfig', '1'],
                                stdout=subprocess.PIPE, stderr=devNull)
    except:
        print 'WARNING: unable to execute arcconf'
        os.chdir(oldDir)
        return 1

    dre = '^\s*Defunct disk drive count\s*:\s*(\d+)'
    defunctRegex = re.compile(dre)
    lre = '^\s*Logical devices/Failed/Degraded\s*:\s*(\d+)/(\d+)/(\d+)'
    logicalRegex = re.compile(lre)
    status = 0
    numLogical = None
    for line in proc.stdout:
        m = defunctRegex.match(line)
        if m is not None and m.group(1) != '0':
            print 'CRITICAL: defunct disk drive count: ' + m.group(1)
            status = 2
            break

        m = logicalRegex.match(line)
        if m is not None:
            numLogical = int(m.group(1))
            if m.group(2) != '0' and m.group(3) != '0':
                print 'CRITICAL: logical devices: %s failed and %s defunct' % \
                    (m.group(2), m.group(3))
                status = 2
                break
            if m.group(2) != '0':
                print 'CRITICAL: logical devices: %s failed' % \
                    (m.group(2))
                status = 2
                break
            if m.group(3) != '0':
                print 'CRITICAL: logical devices: %s defunct' % \
                    (m.group(3))
                status = 2
                break

    ret = proc.wait()
    if status == 0 and ret != 0:
        print 'WARNING: arcconf returned exit status %d' % (ret)
        status = 1

    if status == 0 and numLogical is None:
        print 'WARNING: unable to parse output from arcconf'
        status = 1

    if status == 0:
        print 'OK: %d logical device(s) checked' % numLogical

    os.chdir(oldDir)
    return status


def check3ware():
    # Get the list of controllers
    try:
        proc = subprocess.Popen(['/usr/bin/tw_cli', 'show'],
                                stdout=subprocess.PIPE)
    except:
        print 'WARNING: error executing tw_cli'
        return 1

    regex = re.compile('^(c\d+)')
    controllers = []
    for line in proc.stdout:
        m = regex.match(line)
        if m is not None:
            controllers.append('/' + m.group(1))

    ret = proc.wait()
    if ret != 0:
        print 'WARNING: tw_cli returned exit status %d' % (ret)
        return 1

    # Check each controller
    regex = re.compile('^(p\d+)\s+([\w-]+)')
    failedDrives = []
    numDrives = 0
    for controller in controllers:
        proc = subprocess.Popen(['/usr/bin/tw_cli', controller, 'show'],
                                stdout=subprocess.PIPE)
        for line in proc.stdout:
            m = regex.match(line)
            if m is not None:
                numDrives += 1
                if m.group(2) != 'OK':
                    failedDrives.append(controller + '/' + m.group(1))

        proc.wait()

    if len(failedDrives) != 0:
        print ('CRITICAL: %d failed drive(s): %s' %
               (len(failedDrives), ', '.join(failedDrives)))
        return 2

    if numDrives == 0:
        print 'WARNING: no physical drives found, tw_cli parse error?'
        return 1
    else:
        print 'OK: %d drives checked' % numDrives
        return 0


def checkMegaSas():
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
    numPD = numLD = failedLD = 0
    states = []
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

    print 'OK: optimal, %d logical, %d physical' % (numLD, numPD)
    return 0


def checkZfs():
    try:
        proc = subprocess.Popen(['/sbin/zpool', 'list', '-Honame,health'],
                                stdout=subprocess.PIPE)
    except:
        error = sys.exc_info()[1]
        print 'WARNING: error executing zpool: %s' % str(error)
        return 1

    regex = re.compile('^(\S+)\s+(\S+)')
    status = 0
    msg = ''
    for line in proc.stdout:
        m = regex.match(line)
        if m is not None:
            name = m.group(1)
            health = m.group(2)
            if health != 'ONLINE':
                status = 2

            if msg != '':
                msg += ', '
            msg += name + ': ' + health

    ret = proc.wait()
    if ret != 0:
        print 'WARNING: zpool returned exit status %d' % (ret)
        return 1

    if status:
        print 'CRITICAL: ' + msg
    else:
        print 'OK: ' + msg
    return status


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
    currentDevice = None
    stats = {
        'Active': 0,
        'Working': 0,
        'Failed': 0,
        'Spare': 0
    }
    for line in proc.stdout:
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
    for name in ('Active', 'Working', 'Failed', 'Spare'):
        if msg != '':
            msg += ', '
        msg += name + ': ' + str(stats[name])

    if stats['Failed'] > 0:
        print 'CRITICAL: ' + msg
        return 2
    else:
        print 'OK: ' + msg
        return 0

main()
