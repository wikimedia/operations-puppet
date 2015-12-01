#!/usr/bin/env python
# encoding: utf-8
"""
varnish.py
Gather varnish data for ganglia.
Written by Mark Bergsma <mark@wikimedia.org>
"""

from subprocess import Popen, PIPE
import json
import sys

stats_cache = {}
varnishstat_path = "/usr/bin/varnishstat"

instances = ['']


def metric_init(params):
    global varnishstat_path, instances, stats_cache

    varnishstat_path = params.get('varnishstat', varnishstat_path)

    instances = params.get('instances', "").split(',')
    try:
        instances[instances.index('')] = "varnish"
    except ValueError:
        pass

    stats_cache = {}
    stats_cache = get_stats()

    metrics = []
    for instance in instances:
        for metric, properties in stats_cache[instance].iteritems():
            if metric == "timestamp" or metric.startswith(("VBE.", "LCK.")):
                continue
            slope = (properties['flag'] == 'i' and 'both' or 'positive')
            metric_properties = {
                'name': instance + "." + metric.encode('ascii'),
                'call_back': get_value,
                'time_max': 15,
                'value_type': 'uint',
                'units': (slope == 'positive' and 'N/s' or 'N'),
                'slope': slope,
                'format': '%u',
                'description': properties['description'].encode('ascii'),
                'groups': "varnish " + (instance == "varnish" and
                                        "(default instance)" or instance)
            }
            metrics.append(metric_properties)

    return metrics


def get_value(metric):
    global stats_cache

    instance, metric_name = metric.split('.', 1)
    if metric_name not in stats_cache[instance]:
        get_stats()

    return int(stats_cache[instance].pop(metric_name, {'value': 0})['value'])


def get_stats():
    global stats_cache, instances, GAUGE_METRICS

    for instance in instances:
        params = [varnishstat_path, "-1", "-j"]
        if instance != 'varnish':
            params += ["-n", instance]
        stats_cache[instance] = json.load(Popen(params, stdout=PIPE).stdout)

    return stats_cache


def metric_cleanup():
    pass

if __name__ == '__main__':
    params = {'instances': sys.argv[1]}

    metrics = metric_init(params)

    print "# Varnish plugin for Ganglia Monitor, " +
    "automatically generated config file\n"
    print "modules {\n\tmodule {\n\t\tname = \"varnish\"\n" +
    "\t\tlanguage = \"python\"\n\t\tpath = \"varnish.py\"\n"
    print "\t\tparam instances {\n\t\t\tvalue = \"%s\"\n\t\t}" % ",".join(
        instances)
    print "\t}\n}\n"

    print "collection_group {\n\tcollect_every = 15\n\ttime_threshold = 15\n"
    for metric_properties in metrics:
        print "\tmetric {\n\t\tname = '%(name)s'\n" +
        "\t\ttitle = '%(description)s'\n\t}" % metric_properties
    print "}"
