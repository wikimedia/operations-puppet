#!/usr/bin/env python 
# encoding: utf-8
"""
memcached.py
Gather memcached data for ganglia.
Created by Ryan Lane on 2010-09-07.
"""

import memcache

stats_cache = {}
metric_descriptions = { 'curr_items': 'Current number of items stored', 'bytes': 'Current number of bytes used to store items', 'curr_connectons': 'Number of clients connected', 'global_hitrate': 'Percentage of hits vs misses (get_hits / (get_hits + get_misses))', 'evictions': 'Number of valid items removed from cache to free memoy for new items', 'threads': 'Number of worker threads requested', 'listen_disabled_num': 'Number of times memcached has hit connection limit', 'cmd_flush': 'Number of times flush_all has been called' }
host = 'localhost'
port = '11211'

def metric_init(params):
	global metric_descriptions
	metrics = []

	get_stats()

	for metric in metric_descriptions.keys():
		metric_properties = {
			'name': metric,
			'call_back': get_value,
			'time_max': 15, 
			'value_type': 'uint',
			'units': 'N',
			'slope': 'positive',
			'format': '%u',
			'description': metric_descriptions[metric]
		}
		metrics.append(metric_properties)

	return metrics

def get_value(metric):
	global stats_cache

	if metric == "global_hitrate":
		hits = int(stats_cache.pop('get_hits',0))
		misses = int(stats_cache.pop('get_misses',0))
		hitrate = hits / ( hits + misses )
		return hitrate
	else:
		return int(stats_cache.pop(metric, 0))

def get_stats():
	global stats_cache, host, port

	mc = memcache.Client([host + ':' + port])
	stats = mc.get_stats()
	# stats is an array with one item, an array, whose first entry is the server
	# name, and whose second entry is a dictionary that contains the relevant stats
	stats_cache = stats[0][1]

	return stats_cache

def metric_cleanup():
	pass

if __name__ == '__main__':
	metrics = metric_init({})
	for metric_properties in metrics:
		print "\n\tmetric {\n\t\tname = '%(name)s'\n\t\ttitle = '%(description)s'\n\t}" % metric_properties
