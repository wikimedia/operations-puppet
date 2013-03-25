#!/usr/bin/python

import sys, os, os.path, re, subprocess

def main():
	osName = os.uname()[0]
	if osName == 'SunOS':
		utility = 'zpool'
	elif osName == 'Linux':
		utility = getLinuxUtility()
	else:
		print 'WARNING: Operating system "%s" is not supported by this check script' % (osName)
		sys.exit(1)

	try:
		if utility == None:
			print 'OK: no RAID installed'
			status = 0
		elif utility == 'arcconf':
			status = checkAdaptec()
		elif utility == 'tw_cli':
			status = check3ware()
		elif utility == 'MegaCli':
			status = checkMegaSas()
		elif utility == 'zpool':
			status = checkZfs()
		elif utility == 'mdadm':
			status = checkSoftwareRaid()
		else:
			print 'WARNING: %s is not yet supported by this check script' % (utility)
			status = 1
	except:
		error = sys.exc_info()[1]
		print 'WARNING: check-raid.py encountered exception: ' + str(error)
		status = 1
	
	sys.exit(status)

def getLinuxUtility():
	f = open("/proc/devices", "r")
	regex = re.compile('^\s*\d+\s+(\w+)')
	utility = None
	for line in f:
		m = regex.match(line)
		if m == None:
			continue
		name = m.group(1)
		
		if name == 'aac':
			utility = 'arcconf'
			break
		elif name == 'twe':
			utility = 'tw_cli'
			break
		elif name == 'megadev':
			utility = 'megarc'
			break
		elif name == 'megaraid_sas_ioctl':
			utility = 'MegaCli'
			break
	
	f.close()
	if utility != None:
		return utility

	# Try mdadm
	devices = getSoftwareRaidDevices()
	if len(devices):
		return 'mdadm'

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
		if m != None:
			devices.append(m.group(1))
	proc.wait()

	return devices

def checkAdaptec():
	# Need to change directory so that the log file goes to the right place
	oldDir = os.getcwd()
	os.chdir('/var/log')
	devNull = open('/dev/null', 'w')

	# Check if we need to run arcconf using sudo
	try:
		os.stat('/etc/sudoers.d/nrpe')
		cmd = ['sudo']
	except:
		cmd = []

	# Run the command
	try:
		proc = subprocess.Popen(cmd + ['/usr/bin/arcconf', 'getconfig', '1'], 
				stdout = subprocess.PIPE, stderr = devNull)
	except:
		print 'WARNING: Unable to execute arcconf'
		os.chdir(oldDir)
		return 1

	defunctRegex = re.compile('^\s*Defunct disk drive count\s*:\s*(\d+)')
	logicalRegex = re.compile('^\s*Logical devices/Failed/Degraded\s*:\s*(\d+)/(\d+)/(\d+)')
	status = 0
	numLogical = None
	for line in proc.stdout:
		m = defunctRegex.match(line)
		if m != None and m.group(1) != '0':
			print 'CRITICAL: Defunct disk drive count: ' + m.group(1)
			status = 2
			break

		m = logicalRegex.match(line)
		if m != None:
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

	if status == 0 and numLogical == None:
		print 'WARNING: unable to parse output from arcconf'
		status = 1
	
	if status == 0:
		print 'OK: %d logical device(s) checked' % numLogical

	os.chdir(oldDir)
	return status


def check3ware():
	# Get the list of controllers
	try:
		proc = subprocess.Popen(['/usr/bin/tw_cli', 'show'], stdout = subprocess.PIPE)
	except:
		print 'WARNING: error executing tw_cli'
		return 1

	regex = re.compile('^(c\d+)')
	controllers = []
	for line in proc.stdout:
		m = regex.match(line)
		if m != None:
			controllers.push('/' + m.group(1))
	
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
				stdout = subprocess.PIPE)
		for line in proc.stdout():
			m = regex.match(line)
			if m != None:
				numDrives += 1
				if m.group(2) != 'OK':
					failedDrives.push(controller + '/' + m.group(1))

		proc.wait()
	
	if len(failedDrives) != 0:
		print 'CRITICAL: %d failed drive(s): %s' % \
				(len(failedDrives), ', '.join(failedDrives) )
		return 2

	if numDrives == 0:
		print 'WARNING: no physical drives found, tw_cli parse error?'
		return 1
	else:
		print 'OK: %d drives checked' % numDrives
		return 0

def checkMegaSas():
	try:
		proc = subprocess.Popen(['/usr/bin/MegaCli64', '-LDInfo', '-LALL', '-aALL'], 
				stdout=subprocess.PIPE)
	except:
		error = sys.exc_info()[1]
		print 'WARNING: error executing MegaCli64: %s' % str(error)
		return 1
	
	stateRegex = re.compile('^State:\s*([^\n]*)')
	drivesRegex = re.compile('^Number Of Drives( per span)?:\s*([^\n]*)')
	state = None
	numDrives = None
	for line in proc.stdout:
		m = stateRegex.match(line)
		if m != None:
			state = m.group(1)
			continue
		
		m = drivesRegex.match(line)
		if m != None:
			numDrives = int(m.group(2))
			continue
	
	ret = proc.wait()
	if ret != 0:
		print 'WARNING: MegaCli64 returned exit status %d' % (ret)
		return 1

	if numDrives == None:
		print 'WARNING: Parse error processing MegaCli64 output'
		return 1

	if state != 'Optimal':
		print 'CRITICAL: %s' % (state)
		return 2

	print 'OK: State is %s, checked %d logical device(s)' % (state, numDrives)
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
		if m != None:
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
		print 'WARNING: Unexpectedly checked no devices'
		return 1

	args = ['/sbin/mdadm', '--detail']
	args.extend(devices)
	try:
		proc = subprocess.Popen(args, stdout = subprocess.PIPE)
	except:
		error = sys.exc_info()[1]
		print 'WARNING: error executing mdadm: %s' % str(error)
		return 1

	deviceRegex = re.compile('^(/[^ ]*):$')
	statRegex = re.compile('^ *(Active|Working|Failed|Spare) Devices *: *(\d+)')
	currentDevice = None
	stats = {
		'Active': 0,
		'Working': 0,
		'Failed': 0,
		'Spare': 0
	}
	for line in proc.stdout:
		m = deviceRegex.match(line)
		if m == None:
			if currentDevice == None:
				continue
		else:
			currentDevice = m.group(1)
			continue
		
		m = statRegex.match(line)
		if m == None:
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
