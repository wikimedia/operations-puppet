#!/usr/bin/env python 
# encoding: utf-8
"""
varnish.py
Gather varnish data for ganglia.
Created by Fred Vassard on 2010-04-06.
"""

from subprocess import Popen, PIPE

stats_cache = {}
varnishstat_path = "/usr/bin/varnishstat"

GAUGE_METRICS = set(['n_sess_mem', 'n_sess', 'n_object', 'n_vampireobject', 'n_objectcore', 'n_objecthead', 'n_smf', 'n_smf_frag', 'n_smf_large', 'n_vbe_conn', 'n_wrk', 'n_backend', 'n_expired', 'n_lru_nuked', 'n_lru_saved', 'n_lru_moved', 'n_deathrow', 'sm_nobj', 'sm_balloc', 'sm_bfree', 'sma_nobj', 'sma_nbytes', 'sma_balloc', 'sma_bfree', 'sms_nobj', 'sms_nbytes', 'sms_balloc', 'sms_bfree', 'n_purge'])

instances = ['']

def metric_init(params):
	global varnishstat_path, instances

	metrics = []

	varnishstat_path = params.get('varnishstat', "/usr/bin/varnishstat")

	# First get the metrics list from one instances
	stats = get_stats()

	instances = params.get('instances', "").split(',')

	all_metrics = build_dict()

	for metric in stats.keys():
		if metric.startswith("VBE."): continue
		for instance in instances:
			metric_properties = {
				'name': len(instance) and (instance + '.' + metric) or metric,
				'call_back': get_value,
				'time_max': 15, 
				'value_type': 'uint',
				'units': 'N',
				'slope': ( metric in GAUGE_METRICS and 'both' or 'positive' ),
				'format': '%u',
				'description': all_metrics[metric]
			}
			metrics.append(metric_properties)

	return metrics

def get_value(metric):
	global stats_cache

	if metric not in stats_cache:
		get_stats()

	return int(stats_cache.pop(metric, 0))

def get_stats():
	global stats_cache, instances, GAUGE_METRICS

	stats_cache = {}
	for instance in instances:
		for line in Popen([varnishstat_path, "-1", "-n", instance], stdout=PIPE).stdout:
			key, value, delta = line.split()[0:3]
			if instance != '':
				key = instance + '.' + key 
			stats_cache[key] = value
			if delta.strip() == ".":
				GAUGE_METRICS.add(key)

	return stats_cache

def build_dict():
	all_metrics = {}

	lineno = 0
	for line in Popen([varnishstat_path, "-l"], stderr=PIPE).stderr:
		lineno += 1
		if lineno < 4: continue
		key, value = line.split(None, 1)
		all_metrics[key] = value.strip()

	return all_metrics

def metric_cleanup():
	pass

if __name__ == '__main__':
	metrics = metric_init({})
	for metric_properties in metrics:
		print "\n\tmetric {\n\t\tname = '%(name)s'\n\t\ttitle = '%(description)s'\n\t}" % metric_properties
