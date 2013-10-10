"""
Extracted from ganglia-metrics, v1.3 (svn 69279)
<http://svn.wikimedia.org/viewvc/mediawiki/trunk/ganglia_metrics/>
"""
from GangliaMetrics import *
import time, re, sys, logging

"""
Utilisation metric
"""
class DiskUtilItem(DeltaMetricItem):
	def __init__(self, name, meta):
		DeltaMetricItem.__init__(self, name, meta, '%')
	
	def getValue(self):
		# Get the time spent doing I/O, in milliseconds per second
		value = DeltaMetricItem.getValue(self)
		if self.lastElapsed and value != None:
			# Convert to a percentage of the elapsed time
			return value / 10
		else:
			return None

"""
Load metric
"""
class DiskLoadItem(DeltaMetricItem):
	def __init__(self, name, meta):
		DeltaMetricItem.__init__(self, name, meta)
	
	def getValue(self):
		# Get the time spent doing I/O, in milliseconds per second
		value = DeltaMetricItem.getValue(self)
		if self.lastElapsed and value != None:
			# Convert to a plain ratio
			return value / 1000
		else:
			return None

"""
Statistics from /proc/diskstats
Requires Linux 2.6+
"""
class DiskStats(MetricCollection):
	# Field indexes
	BLANK_INITIAL_SPACE = 0
	MAJOR = 1
	MINOR = 2
	NAME = 3
	READS = 4
	READS_MERGED = 5
	SECTORS_READ = 6
	MS_READING = 7
	WRITES = 8
	WRITES_MERGED = 9
	SECTORS_WRITTEN = 10
	MS_WRITING = 11
	REQS_PENDING = 12
	MS_TOTAL = 13
	MS_WEIGHTED = 14
	
	def __init__(self):
		self.metrics = {
			'diskio_read_bytes': DeltaMetricItem(
				'diskio_read_bytes', 
				{
					'TITLE': 'Disk read bytes',
					'DESC': 'Bytes read from block devices',
					'GROUP': 'disk'
				},
				'bytes/sec'),
			'diskio_write_bytes': DeltaMetricItem(
				'diskio_write_bytes',
				{
					'TITLE': 'Disk write bytes',
					'DESC': 'Bytes written to block devices',
					'GROUP': 'disk'
				},
				'bytes/sec'),
			'diskio_read_load': DiskLoadItem(
				'diskio_read_load',
				{
					'TITLE': 'Disk read load',
					'DESC': 'Time spent reading divided by wall clock time, averaged over devices (/proc/diskstats field #4)',
					'GROUP': 'disk'
				}),
			'diskio_write_load': DiskLoadItem(
				'diskio_write_load',
				{
					'TITLE': 'Disk write load',
					'DESC': 'Time spent writing divided by wall clock time, averaged over devices (/proc/diskstats field #8)',
					'GROUP': 'disk'
				}),
			'diskio_total_load': DiskLoadItem(
				'diskio_total_load',
				{
					'TITLE': 'Disk total load',
					'DESC': 'Queue size multiplied by total I/O time, divided by wall clock time, averaged over devices (/proc/diskstats field #11)',
					'GROUP': 'disk'
				}),
			'diskio_util': DiskUtilItem(
				'diskio_util',
				{
					'TITLE': 'Disk utilisation',
					'DESC': 'Time spent in I/O divided by wall clock time, averaged over devices (/proc/diskstats field #10)',
					'GROUP': 'disk',
				}),
			'diskio_devices': StringMetric(
				'diskio_devices',
				{
					'TITLE': 'Disk devices monitored',
					'DESC': 'Devices monitored in diskio_* metrics',
					'GROUP': 'disk'
				})
		}
		self.delimiterRegex = re.compile(r"\s+")
		self.deviceRegex = re.compile(r"^[sh]d[a-z]$")
		self.disabled = False

	def update(self):
		if self.disabled:
			return False
		
		try:
			procfile = open('/proc/diskstats', 'r')
		except IOError:
			type, value = sys.exc_info()[:2]
			logger = logging.getLogger('GangliaMetrics')
			logger.warning("Unable to open /proc/diskstats: %s\n" % value)
			self.disabled = True
			return False
		
		contents = procfile.read(100000)
		refTime = time.time()
		procfile.close()
		lines = contents.splitlines()

		devCount = 0
		sums = None
		devNames = ''
		for line in lines:
			fields = self.delimiterRegex.split(line)
			if self.deviceRegex.search(fields[self.NAME]) == None or \
			len(fields) < self.MS_WEIGHTED or \
			fields[self.READS] == 0:
				continue
			
			if sums == None:
				sums = [0] * len(fields)

			# Sum the summable stats
			for i in xrange(len(fields)):
				if fields[i].isdigit():
					sums[i] += long(fields[i])

			devCount += 1
			if devNames != '':
				devNames += ', '
			devNames += fields[self.NAME]
		
		# Put the summed stats into metrics
		if devCount:
			# The sector size in this case is hard-coded in the kernel as 512 bytes
			# There doesn't appear to be any simple way to retrieve that figure
			self.metrics['diskio_read_bytes'].set(sums[self.SECTORS_READ] * 512, refTime)
			self.metrics['diskio_write_bytes'].set(sums[self.SECTORS_WRITTEN] * 512, refTime)
			
			self.metrics['diskio_read_load'].set(sums[self.MS_READING], refTime, devCount)
			self.metrics['diskio_write_load'].set(sums[self.MS_WRITING], refTime, devCount)
			self.metrics['diskio_total_load'].set(sums[self.MS_WEIGHTED], refTime, devCount)
			self.metrics['diskio_util'].set(sums[self.MS_TOTAL], refTime, devCount)

		self.metrics['diskio_devices'].set(devNames)

		return devCount != 0


