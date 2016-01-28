#!/bin/env python

import sys
import os
import threading
import time

descriptors = list()
_Worker_Thread = None
_Lock = threading.Lock()  # synchronization lock
metric_results = {}


def metric_of(name):
    global metric_results
    return metric_results.get(name, 0)

# These are the defaults set for the metric attributes
Desc_Skel = {
    "name": "N/A",
    "call_back": metric_of,
    "time_max": 60,
    "value_type": "uint",
    "units": "N/A",
    "slope": "both",  # zero|positive|negative|both
    "format": "%d",
    "description": "N/A",
    "groups": "OpenStreetMap",
}


# Create your queries here. Keys whose names match those defined in the default
# set are overridden. Any additional key-value pairs (i.e. query) will not be
# added to the Ganglia metric definition but can be useful for data purposes.
def get_planet_osm_lag(obj):
    import datetime
    try:
        with open(obj.state_path, "r") as f:
            for line in f.readlines():
                if line.startswith("timestamp="):
                    t = datetime.datetime.strptime(
                        line.strip().split('=')[1], "%Y-%m-%dT%H\:%M\:%SZ")
                    r = datetime.datetime.now() - t
                    return r.seconds
    except IOError as e:
        print_exception("Could not open file", e)
        raise

metric_defs = {
    "osm_sync_lag": {
        "description": "Number of seconds behind planet.osm",
        "units": "seconds",
        "query": get_planet_osm_lag,
    },
}


def print_exception(custom_msg, exception):
    error_msg = custom_msg or "An error has occurred"
    print "%s %s" % (error_msg, exception),


class UpdateMetricThread(threading.Thread):
    def __init__(self, params):
        threading.Thread.__init__(self)
        self.running = False
        self.shuttingdown = False
        self.refresh_rate = 30
        self.state_path = "/srv/osmosis/state.txt"

        param_list = ["state_path", "refresh_rate"]
        for attr in param_list:
            if attr in params:
                setattr(self, attr, params[attr])

    def shutdown(self):
        self.shuttingdown = True
        if not self.running:
            return
        self.join()

    def run(self):
        self.running = True

        while not self.shuttingdown:
            _Lock.acquire()
            try:
                self.update_metric()
            except Exception as e:
                print_exception("Unable to update metrics", e)
            _Lock.release()
            time.sleep(int(self.refresh_rate))

        self.running = False

    def update_metric(self):
        global metric_results

        converter = {
            'float': float,
            'uint': int
        }

        for metric_name, metric_attrs in metric_defs.iteritems():
            data = metric_attrs["query"](self)
            convert_fn = converter.get(
                metric_defs[metric_name].get("value_type"), int)
            metric_results[metric_name] = convert_fn(data)


def metric_init(params):
    global descriptors, Desc_Skel, _Worker_Thread

    _Worker_Thread = UpdateMetricThread(params)
    _Worker_Thread.start()

    for metric_desc in metric_defs:
        descriptors.append(
            create_desc(metric_desc, Desc_Skel, metric_defs[metric_desc]))

    return descriptors


def create_desc(metric_name, skel, prop):
    return dict(
        skel.items() +
        [('name', metric_name)] +
        [(k, v) for k, v in prop.items() if k in skel]
    )


def metric_cleanup():
    _Worker_Thread.shutdown()

if __name__ == '__main__':
    import argparse

    parser = argparse.ArgumentParser(
        description='Debug the Ganglia OSM module.')
    parser.add_argument(
        '--state_path', type=str, default='/srv/osmosis/state.txt',
        help='The path where state.txt resides. (default: %(default)s).')
    parser.add_argument(
        '--refresh_rate', type=int, default=10,
        help='The interval, in seconds, between query executions ' +
             'metric collection. (default: %(default)s).')
    args = parser.parse_args()
    params = vars(args)
    try:
        metric_init(params)
        while True:
            for d in descriptors:
                v = d['call_back'](d['name'])
                print ('value for %s is '+d['format']) % (d['name'],  v)
            print
            time.sleep(5)
    except KeyboardInterrupt:
        time.sleep(0.2)
        os._exit(1)
