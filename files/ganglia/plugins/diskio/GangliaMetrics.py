"""
Extracted from ganglia-metrics, v1.3 (svn 69279)
<http://svn.wikimedia.org/viewvc/mediawiki/trunk/ganglia_metrics/>
"""
from xdrlib import Packer
import time, logging, socket

""" Metric base class """

class Metric(object):
	def __init__(self, name, meta, units = ''):
		self.name = name
		self.units = units
		self.type = 'float'
		self.meta = meta
		self.lastSendTime = 0
		self.lastMetadataSendTime = 0

		self.slope = 'both'
		self.tmax = 60
		self.dmax = 0
		self.interval = 10
		self.metadataInterval = 60
		self.hostname = socket.gethostname()
		self.format = '%.1f'

		self.value = 0

		self.gangliaVersion = 3 # TODO: get this from the system
		self.debug = False

		self.formatIDs = {
			'full': 128,
			'ushort': 128 + 1,
			'short': 128 + 2,
			'int': 128 + 3,
			'uint': 128 + 4,
			'string': 128 + 5,
			'float': 128 + 6,
			'double': 128 + 7,
			'request': 128 + 8
		}
	
	def isReady(self):
		return time.time() - self.lastSendTime >= self.interval
	
	def send(self, sock, address):
		value = self.getValue()
		if value != None:
			if self.debug:
				logging.getLogger('GangliaMetrics').info('Sending %s = %s' % (self.name, value))

			if self.gangliaVersion >= 3:
				self.sendV3Data(sock, address, value)
			else:
				self.sendV2Data(sock, address, value)
			self.lastSendTime = time.time()

	def sendV2Data(self, sock, address, value):
		packer = Packer()
		packer.pack_enum(0) # metric_user_defined
		packer.pack_string(self.type)
		packer.pack_string(self.name)
		packer.pack_string(str(value))
		packer.pack_string(self.units)
		if self.slope == 'zero':
			slope = 0
		else:
			slope = 3 # both
		packer.pack_uint(slope)
		packer.pack_uint(self.tmax)
		packer.pack_uint(self.dmax)

		sock.sendto(packer.get_buffer(), address)
	
	def sendV3Data(self, sock, address, value):
		if time.time() - self.lastMetadataSendTime >= self.metadataInterval:
			self.sendMetadata(sock, address)

		packer = Packer()
		packer.pack_enum(self.formatIDs[self.type])
		packer.pack_string(self.hostname)
		packer.pack_string(self.name)
		packer.pack_bool(False) # spoof = false
		packer.pack_string(self.format)
		self.packValue(packer, value)

		sock.sendto(packer.get_buffer(), address)

	def packValue(self, packer, value):
		if self.type == 'int':
			packer.pack_int(value)
		elif self.type == 'string':
			packer.pack_string(value)
		elif self.type == 'float':
			packer.pack_float(value)
		elif self.type == 'double':
			packer.pack_double(value)
		else:
			logging.getLogger('GangliaMetrics').error('Cannot pack type ' + self.type)

	def sendMetadata(self, sock, address):
		self.lastMetadataSendTime = time.time()
		packer = Packer()
		packer.pack_enum(self.formatIDs['full'])
		packer.pack_string(self.hostname)
		packer.pack_string(self.name)
		packer.pack_bool(False) # spoof = false
		packer.pack_string(self.type)
		packer.pack_string(self.name)
		packer.pack_string(self.units)
		if self.slope == 'zero':
			slope = 0
		else:
			slope = 3
		packer.pack_uint(slope)
		packer.pack_uint(self.tmax)
		packer.pack_uint(self.dmax)

		packer.pack_uint(len(self.meta)) # array length
		for name, value in self.meta.items():
			packer.pack_string(name)
			packer.pack_string(value)

		sock.sendto(packer.get_buffer(), address)

	def getValue(self):
		return self.value

	def set(self, value):
		self.value = value

"""
A metric which works by querying a system counter. The counter typically 
increases monotonically, but may occasionally overflow. The difference 
between consecutive values is calculated, the result is a count per second. 
"""
class DeltaMetric(Metric):
	def __init__(self, name, meta, units = ''):
		Metric.__init__(self, name, meta, units)
		self.lastCounterValue = 0
		self.lastRefTime = None
		self.lastElapsed = None
	
	def getValue(self):
		counter, refTime, divideBy = self.getCounterValue()

		if self.lastRefTime is None:
			# Initial value
			value = None
		else:
			elapsed = refTime - self.lastRefTime
			self.lastElapsed = elapsed
			if elapsed == 0:
				# Time elapsed is too short
				value = None
			elif counter >= self.lastCounterValue:
				# Normal increment
				value = float(counter - self.lastCounterValue) / float(elapsed) / divideBy
			elif self.lastCounterValue > (1L << 32):
				# Assume 64-bit counter overflow
				value = float(counter + (1L<<64) - self.lastCounterValue) / float(elapsed) / divideBy
			else:
				# Assume 32-bit counter overflow
				value = float(counter + (1L<<32) - self.lastCounterValue) / float(elapsed) / divideBy
		
		self.lastRefTime = refTime
		self.lastCounterValue = counter
		return value

	def getCounterValue(self):
		raise NotImplementedError

"""
A rolling average metric
"""
class RollingMetric(Metric):
	def __init__(self, name, meta, avPeriod = 60, units = ''):
		Metric.__init__(self, name, meta, units)
		self.queue = []
		self.sum = 0
		self.targetSize = avPeriod / self.interval
		self.head = 0

	def getValue(self):
		if len(self.queue) == 0:
			return None
		else:
			return float(self.sum) / len(self.queue)

	def set(self, value):
		if value == None:
			self.queue = []
			return

		self.sum += value
		if len(self.queue) == self.targetSize:
			self.head = (self.head + 1) % self.targetSize
			self.sum -= self.queue[self.head]
			self.queue[self.head] = value
		else:
			self.queue.append(value)


"""
A metric which averages pushed values over the polling period
If no value is pushed during a given polling interval, the previous average is returned
"""
class PushMetric(Metric):
	def __init__(self, name, meta, units = ''):
		Metric.__init__(self, name, meta, units)
		self.lastAv = None
		self.sum = 0
		self.count = 0
	
	def set(self, value):
		self.sum += value
		self.count += 1
	
	def getValue(self):
		if self.count == 0:
			return self.lastAv
		else:
			self.lastAv = self.sum / self.count
			self.sum = 0
			self.count = 0
			return self.lastAv

"""
Simple delta metric class intended for use in metric collections
"""
class DeltaMetricItem(DeltaMetric):
	value = 0
	refTime = 0
	divideBy = 1

	def getCounterValue(self):
		return (self.value, self.refTime, self.divideBy)

	def set(self, value, refTime, divideBy = 1):
		self.value = value
		self.refTime = refTime
		self.divideBy = divideBy

"""
Metric collection base class
"""
class MetricCollection(object):
	def __init__(self):
		self.metrics = {}

	def __iter__(self):
		if self.update():
			return self.metrics.values().__iter__()
		else:
			return [].__iter__()
	
	def update(self):
		return True
	
	def add(self, metric):
		self.metrics[metric.name] = metric

"""
String metric
"""
class StringMetric(Metric):
	def __init__(self, name, meta):
		Metric.__init__(self, name, meta)
		self.interval = 60
		self.type = 'string'
		self.format = '%s'
		self.value = ''
