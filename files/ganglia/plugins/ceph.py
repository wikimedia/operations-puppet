#!/usr/bin/env python 
# encoding: utf-8
"""
ceph.py
Gather ceph OSD data for ganglia.
Written by Mark Bergsma <mark@wikimedia.org>
"""

from subprocess import Popen, PIPE
import json, os, sys

stats_cache = {}
prev_values = {}
metric_types = {}
ceph_path = "/usr/bin/ceph"

instances = ['']

def metric_init(params):
	global ceph_path, instances, stats_cache, metrics, metric_types

	ceph_path = params.get('ceph', ceph_path)

	instances = params.get('instances', "").split(',')

	stats_cache = {}
	metrics = []
	metric_types = {}
	for instance in instances:
		metric_types[instance] = json.load(Popen([ceph_path, "--admin-daemon", "/var/run/ceph/ceph-osd.%s.asok" % instance, "perf", "schema"], stdout=PIPE).stdout)
		
		for section in metric_types[instance]:
			if section not in ("osd", "filestore"): continue
			for metric, properties in metric_types[instance][section].iteritems():
				name = instance + "." + section.encode('ascii') + "." + metric.encode('ascii')
				counter = bool(properties['type'] & 0b1000)
				valtype = (properties['type'] & 0b10 == 0b10) and 'uint' or 'float'
				metric_properties = {
					'name': name,
					'call_back': get_value,
					'time_max': 15,
					'value_type': valtype,
					'units': ( counter and 'N/s' or 'N' ),
					'slope': ( counter and "positive" or "both" ),
					'format': ( valtype == "uint" and r'%u' or r'%f' ),
					'description': "%s %s" % (section.encode('ascii'), metric.encode('ascii')),
					'groups': "ceph osd " + instance
				}
				metrics.append(metric_properties)

	return metrics

def get_value(metric):
	global stats_cache, prev_values, metric_types

	instance, section, metric_name = metric.split('.', 2)

	t = metric_types[instance][section][metric_name]['type']
	try:
		v = stats_cache[instance][section].pop(metric_name)
	except KeyError:
		get_stats()
		v = stats_cache[instance][section].pop(metric_name)

	if t & 0b100 > 0:
		# Average
		try:
			p = prev_values[instance][section][metric_name]
			r = (v['sum'] - p['sum']) / (v['avgcount'] - p['avgcount'])
 		except KeyError:
			r = 0
		finally:
			prev_values.setdefault(instance, {}).setdefault(section, {})[metric_name] = v
	else:
		r = v

	if t & 1 == 1:
		return float(r)
	else:
		return int(r)


def get_stats():
	global stats_cache, instances

	for instance in instances:
		stats_cache[instance] = json.load(Popen([ceph_path, "--admin-daemon", "/var/run/ceph/ceph-osd.%s.asok" % instance, "perf", "dump"], stdout=PIPE).stdout)

	return stats_cache

def metric_cleanup():
	pass

if __name__ == '__main__':
	params = { 'instances': sys.argv[1] }

	metrics = metric_init(params)

	print "# Ceph plugin for Ganglia Monitor, automatically generated config file\n"
	print "modules {\n\tmodule {\n\t\tname = \"ceph\"\n\t\tlanguage = \"python\"\n\t\tpath = \"ceph.py\"\n"
	print "\t\tparam instances {\n\t\t\tvalue = \"%s\"\n\t\t}" % ",".join(instances)
	print "\t}\n}\n"

	print "collection_group {\n\tcollect_every = 15\n\ttime_threshold = 15\n"
	for metric_properties in metrics:
		print "\tmetric {\n\t\tname = '%(name)s'\n\t\ttitle = '%(description)s'\n\t}" % metric_properties
	print "}"