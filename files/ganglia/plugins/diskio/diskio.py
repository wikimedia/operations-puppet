# -*- coding: utf-8 -*-
"""
 GangliaMetrics DiskStats gmond adapter

 This module serves as an adapter between ganglia_metrics and gmond.
 The ganglia_metrics package was designed to encode and transmit metrics to
 Ganglia by itself. Gmond, on the other hand, expects Python modules to
 implement a set of interfaces that expose metric definitions and values but
 to leave the actual logging of these values to gmond itself. This module
 wraps the DiskStats metric collection from ganglia_metrics with
 a gmond-compatible interface.

 Needs DiskStats.py & GangliaMetrics.py from ganglia_metrics v1.3 (rev. 69279)
 See <http://svn.wikimedia.org/viewvc/mediawiki/trunk/ganglia_metrics/>.

"""
import itertools
import threading
import time

import DiskStats


stats = DiskStats.DiskStats()
values = {metric: None for metric in stats.metrics}

def get_descriptor(metric):
    """Construct a gmond metric descriptor out of a Metric object."""
    return {
        'name': metric.name,
        'format': metric.format,
        'slope': metric.slope,
        'time_max': metric.tmax,
        'call_back': values.get,
        'units': metric.units,
        'value_type': metric.type,
        'title': metric.meta['TITLE'],
        'description': metric.meta['DESC'],
        'groups': metric.meta['GROUP'],
    }

def metric_init(params=None):
    """Part of Gmond interface; initialize metrics."""
    metrics = [get_descriptor(m) for m in stats.metrics.values()]
    threading.Timer(10, update).start()
    return metrics

def update():
    """
    Update stats and schedule another update after a 10-second delay.
    The 10-second interval is inexact because (a) threading.Timer is inexact,
    (b) it does not take into account the cost of the update itself. But it'll
    be exact enough for us.
    """
    stats.update()
    for name in values:
        values[name] = stats.metrics[name].getValue()
    threading.Timer(10, update).start()

def metric_cleanup():
    """Part of Gmond interface."""
    pass


if __name__ == '__main__':
    metrics = metric_init()
    while 1:
        time.sleep(10)
        for metric in metrics:
            name = metric['name']
            value = metric['call_back'](name)
            print('%s: %s' % (name, value))
        print '----'
