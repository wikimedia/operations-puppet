#!/usr/bin/env python

# htcpseqcheck_ganglia.py
# Ganglia gmond module integration

import htcpseqcheck, util
import threading, sys, socket, datetime

from util import debug

# Globals
metrics = {}

class HTCPSeqCheckThread(threading.Thread):
    
    name = "HTCPSeqCheck"
    daemon = True
    
    def run(self, kwargs={}):
        try:
            sock = util.open_htcp_socket(kwargs.get('host', ""), kwargs.get('port', 4827))
        
            # Join a multicast group if requested
            if 'multicast_group' in kwargs:
                debug('Joining multicast group ' + kwargs['multicast_group'])
                util.join_multicast_group(sock, kwargs['multicast_group'])

            # Set sys.stdout to None; ganglia will do so anyway, and we
            # can detect this in htcpseqcheck.

            # Start receiving HTCP packets
            htcpseqcheck.receive_htcp(sock)
        except socket.error, msg:
            print >> sys.stderr, msg[1]
            sys.exit(1)

def build_metrics_dict():
    "Builds a dict of metric parameter dicts"

    metrics = {
        'htcp_losspct':  {
            'value_type':   "float",
            'units':        "%",
            'format':       "%.2f",
            'slope':        "both",
            'description':  "HTCP packet loss percentage",
            'int_name':     None,
        },
        'htcp_lost': {
            'value_type':   "uint",
            'units':        "packets/s",
            'format':       "%u",
            'slope':        "positive",
            'description':  "Lost HTCP packets",
            'int_name':     "lost",
        },
        'htcp_dequeued': {
            'value_type':   "uint",
            'units':        "packets/s",
            'format':       "%u",
            'slope':        "positive",
            'description':  "Dequeued HTCP packets",
            'int_name':     "dequeued",
        },
        'htcp_outoforder': {
            'value_type':   "uint",
            'units':        "packets/s",
            'format':       "%u",
            'slope':        "positive",
            'description':  "HTCP packets received out-of-order",
            'int_name':     "outoforder",
        },
        'htcp_dups': {
            'value_type':   "uint",
            'units':        "dups/s",
            'format':       "%u",
            'slope':        "positive",
            'description':  "Duplicate HTCP packets",
            'int_name':     "dups",
        },
        'htcp_ancient': {
            'value_type':   "uint",
            'units':        "packets/s",
            'format':       "%u",
            'slope':        "positive",
            'description':  "Ancient HTCP packets",
            'int_name':     "ancient",
        },
        'htcp_received': {
            'value_type':   "uint",
            'units':        "packets/s",
            'format':       "%u",
            'slope':        "positive",
            'description':  "Received HTCP packets",
            'int_name':     "received",
        },
        'htcp_sources':  {
            'value_type':   "uint",
            'units':        "sources",
            'format':       "%u",
            'slope':        "both",
            'description':  "Unique HTCP senders",
            'int_name':     None,
        }
    }
    
    # Add common values
    for metricname, metric in metrics.iteritems():
        metric.update({
            'name': metricname,
            'call_back': metric_handler,
            'time_max': 15,
            'groups': "htcp"
        })
    
    return metrics

def metric_init(params):
    # gmond module initialization
    global metrics
    
    # Start HTCP metrics collection in a separate thread
    HTCPSeqCheckThread().start()

    metrics = build_metrics_dict() 
    return list(metrics.values())

def metric_cleanup(params):
    pass

def metric_handler(name):
    global metrics, silenceTime

    metric = metrics[name]
    
    try:
        with htcpseqcheck.stats_lock:   # Critical section
            if name == "htcp_losspct":
                return float(htcpseqcheck.slidingcounts['lost']) / htcpseqcheck.slidingcounts['dequeued'] * 100
            elif name == "htcp_sources":
                return len(htcpseqcheck.sourcebuf)
            else:
                return htcpseqcheck.totalcounts[metric['int_name']]
    except:
        return None

if __name__ == '__main__':
    for metric in build_metrics_dict().itervalues():
        print "  metric {\n    name = \"%(name)s\"\n    title = \"%(description)s\"\n  }\n" % metric